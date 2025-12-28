import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "force-topic-scroll-top",

  initialize() {
    withPluginApi("1.8.0", (api) => {
      api.modifyClass("route:topic", {
        pluginId: "force-topic-scroll-top",

        activate() {
          this._super(...arguments);

          // Topic load hotay hi top par le jao
          requestAnimationFrame(() => {
            window.scrollTo({ top: 0, left: 0, behavior: "auto" });
          });
        },
      });
    });
  },
};