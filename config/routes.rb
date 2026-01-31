# frozen_string_literal: true

DiscourseTopicGallery::Engine.routes.draw do
  get "/:topic_id" => "topic_gallery#show", :constraints => { topic_id: /\d+/ }
end

Discourse::Application.routes.draw do
  mount ::DiscourseTopicGallery::Engine, at: "topic-gallery"
end
