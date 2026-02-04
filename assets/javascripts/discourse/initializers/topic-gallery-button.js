import { withPluginApi } from "discourse/lib/plugin-api";
import PostMenuGalleryButton from "../components/post-menu-gallery-button";

export default {
  name: "topic-gallery-button",

  initialize() {
    withPluginApi((api) => {
      const siteSettings = api.container.lookup("service:site-settings");
      if (siteSettings.topic_gallery_post_menu_button) {
        api.registerValueTransformer(
          "post-menu-buttons",
          ({ value: dag, context: { buttonKeys } }) => {
            dag.add("gallery", PostMenuGalleryButton, {
              before: buttonKeys.SHOW_MORE,
            });
          }
        );
      }
    });
  },
};
