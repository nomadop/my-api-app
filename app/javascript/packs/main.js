import Vue from 'vue/dist/vue.esm';
import VueMaterial from 'vue-material';

Vue.use(VueMaterial);

Vue.component('booster-creators', function (resolve) {
  require(['../pages/booster_creators/booster_creators.vue'], resolve)
});

Vue.component('inventory', function (resolve) {
  require(['../pages/inventory/inventory.vue'], resolve)
});

Vue.component('my-listings', function (resolve) {
  require(['../pages/my_listings/my_listings.vue'], resolve)
});

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#vue-app',
    data: () => ({
      nav_visible: false,
      snackbar: {
        active: false,
        message: null,
      },
      confirm: {
        title: null,
        active: false,
        callback: () => {},
      },
    }),
    methods: {
      on_confirm: function (confirm) {
        this.confirm = {
          active: true,
          ...confirm,
        };
      },
      on_message: function (message) {
        this.snackbar = {
          active: true,
          ...message,
        }
      }
    }
  });
});
