import Vue from 'vue/dist/vue.esm';
import VueMaterial from 'vue-material';
import { wrap_fetch } from "../utilities/wrapper";

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

Vue.component('account-histories', function (resolve) {
  require(['../pages/account_histories/account_histories.vue'], resolve)
});

function fetch_accounts() {
  return fetch('/accounts')
    .then(response => response.json())
    .then(accounts => this.accounts = accounts);
}

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#vue-app',
    data: () => ({
      accounts: [],
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
      fetch_accounts: wrap_fetch(fetch_accounts),
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
    },
    created() {
      this.fetch_accounts();
    }
  });
});
