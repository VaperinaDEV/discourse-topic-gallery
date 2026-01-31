import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";

export default class GalleryLinkButton extends Component {
  @service router;

  @action
  openGallery() {
    this.router.transitionTo(
      `/t/${this.args.topic.slug}/${this.args.topic.id}/gallery`
    );
  }

  <template>
    <DButton
      @action={{this.openGallery}}
      @icon="images"
      @title="discourse_topic_gallery.gallery_button_title"
      class="btn-default gallery-link-btn"
    />
  </template>
}
