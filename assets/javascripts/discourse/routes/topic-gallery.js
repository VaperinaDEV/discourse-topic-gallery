import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class TopicGalleryRoute extends DiscourseRoute {
  async model(params) {
    return await ajax(`/topic-gallery/${params.id}`);
  }
}
