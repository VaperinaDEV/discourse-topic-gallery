# frozen_string_literal: true

module DiscourseTopicGallery
  class TopicGalleryController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    PAGE_SIZE = 30

    def show
      allowed_groups = SiteSetting.topic_gallery_allowed_groups_map
      everyone_allowed = allowed_groups.include?(Group::AUTO_GROUPS[:everyone])
      unless everyone_allowed || current_user&.in_any_groups?(allowed_groups)
        raise Discourse::InvalidAccess
      end

      topic = Topic.find_by(id: params[:topic_id])
      raise Discourse::NotFound unless topic
      guardian.ensure_can_see!(topic)

      page = [params[:page].to_i, 0].max
      visible_posts = visible_posts_scope(topic)

      if params[:username].present?
        filter_user = User.find_by_username(params[:username])
        visible_posts = visible_posts.where(user_id: filter_user.id) if filter_user
      end

      if params[:post_number].present?
        visible_posts = visible_posts.where("posts.post_number >= ?", params[:post_number].to_i)
      end

      if params[:from_date].present?
        from = begin Date.parse(params[:from_date]) rescue nil end
        visible_posts = visible_posts.where("posts.created_at >= ?", from.beginning_of_day) if from
      end
      if params[:to_date].present?
        to = begin Date.parse(params[:to_date]) rescue nil end
        visible_posts = visible_posts.where("posts.created_at <= ?", to.end_of_day) if to
      end

      visible_posts_sub = visible_posts.select(:id)

      refs_with_total =
        UploadReference
          .joins("INNER JOIN posts ON posts.id = upload_references.target_id")
          .joins("INNER JOIN users ON users.id = posts.user_id")
          .joins("INNER JOIN uploads ON uploads.id = upload_references.upload_id")
          .where(target_type: "Post", target_id: visible_posts_sub)
          .where("uploads.width > 100 AND uploads.height > 100")
          .where("uploads.extension NOT IN ('ico', 'svg')")
          .select(
            "upload_references.upload_id",
            "upload_references.id AS ref_id",
            "posts.id AS post_id",
            "posts.post_number",
            "posts.cooked AS post_cooked", # Needed to check for Onebox classes
            "users.username AS poster_username",
            "COUNT(*) OVER() AS total_count",
          )
          .order("posts.post_number ASC, upload_references.id ASC")
          .offset(page * PAGE_SIZE)
          .limit(PAGE_SIZE)

      refs_array = refs_with_total.to_a
      total = refs_array.first&.total_count.to_i
      upload_ids = refs_array.map(&:upload_id)

      uploads = Upload.where(id: upload_ids).includes(:optimized_images).index_by(&:id)
      images = serialize_uploads_from_refs(refs_array, uploads, topic)

      render json: {
               title: topic.title,
               slug: topic.slug,
               id: topic.id,
               images: images,
               page: page,
               hasMore: ((page + 1) * PAGE_SIZE) < total,
               total: total,
             }
    end

    private

    def visible_posts_scope(topic)
      allowed_types = [Post.types[:regular]]
      allowed_types << Post.types[:whisper] if guardian.can_see_whispers?

      scope = Post.where(topic_id: topic.id).where(deleted_at: nil).where(hidden: false).where(post_type: allowed_types)
      if current_user
        ignored_ids = IgnoredUser.where(user_id: current_user.id).select(:ignored_user_id)
        scope = scope.where.not(user_id: ignored_ids)
      end
      scope
    end

    def serialize_uploads_from_refs(refs, uploads, topic)
      refs.map do |ref|
        upload = uploads[ref.upload_id]
        next unless upload

        # ONEBOX EXCLUSION LOGIC
        # We parse the HTML of the post to see where this image is located.
        doc = Nokogiri::HTML5.fragment(ref.post_cooked)
        
        # Find the image or a link containing the image short URL or full URL
        # Discourse uses the upload's short_url (upload://...) or full URL in the cooked HTML.
        search_term = upload.short_url || upload.url
        img_node = doc.at_css("img[src*='#{upload.sha1}'], img[src*='#{upload.id}']")
        
        if img_node
          # Check if any parent has the onebox or video-thumbnail class
          is_onebox = img_node.ancestors(".onebox, .onebox-body, .video-thumbnail, .video-container").any?
          next if is_onebox # Skip this image if it's inside a Onebox
        end

        thumb_w = upload.thumbnail_width || upload.width
        thumb_h = upload.thumbnail_height || upload.height
        ext = ".#{upload.extension}"

        optimized = upload.optimized_images.detect do |oi|
          oi.width == thumb_w && oi.height == thumb_h && oi.extension == ext
        end
        optimized ||= OptimizedImage.create_for(upload, thumb_w, thumb_h)
        thumbnail_raw_url = optimized&.url || upload.url

        {
          id: upload.id,
          thumbnailUrl: UrlHelper.cook_url(thumbnail_raw_url, secure: upload.secure?, local: true),
          url: UrlHelper.cook_url(upload.url, secure: upload.secure?, local: true),
          width: upload.width,
          height: upload.height,
          filesize: upload.human_filesize,
          filename: upload.original_filename,
          downloadUrl: upload.short_path,
          username: ref.poster_username, 
          postId: ref.post_id,
          postNumber: ref.post_number,
          postUrl: "/t/#{topic.slug}/#{topic.id}/#{ref.post_number}",
        }
      end.compact
    end
  end
end
