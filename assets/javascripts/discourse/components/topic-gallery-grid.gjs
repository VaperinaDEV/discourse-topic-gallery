import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";

export default class TopicGalleryGrid extends Component {
  @action
  openLightbox(image, event) {
    event.preventDefault();
    window.open(image.url, "_blank");
  }

  <template>
    <div class="topic-gallery-container">
      {{#if @images.length}}
        <div class="gallery-grid">
          {{#each @images as |image|}}
            <div class="gallery-card">
              <a
                href={{image.url}}
                class="image-preview-link"
                {{on "click" (fn this.openLightbox image)}}
              >
                <span class="image-wrapper">
                  <img
                    src={{image.thumbnailUrl}}
                    class="gallery-image"
                    loading="lazy"
                    alt=""
                  />
                </span>
              </a>
              <div class="gallery-meta">
                <a
                  href="/u/{{image.username}}"
                  class="gallery-author"
                >@{{image.username}}</a>
                <a
                  href={{image.postUrl}}
                  class="gallery-post-link"
                >#{{image.id}}</a>
              </div>
            </div>
          {{/each}}
        </div>
      {{else}}
        <div class="no-images-message">
          <p>No images found in this topic.</p>
        </div>
      {{/if}}
    </div>
  </template>
}
