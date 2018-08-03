import Vue from 'vue/dist/vue.esm';
import VueMaterial from 'vue-material';
import Chart from 'chart.js';
import * as _ from 'lodash';

import { wrap_fetch } from "../utilities/wrapper";

Chart.defaults.global.defaultFontColor = 'rgba(255, 255, 255, .7)';
Chart.defaults.global.layout.padding = { left: 16, right: 16 };
Chart.defaults.global.hover.intersect = false;
Chart.defaults.global.tooltips.intersect = false;
Chart.defaults.global.responsive = true;
Chart.defaults.global.maintainAspectRatio = false;

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

Vue.component('order-histogram', function (resolve) {
  require(['../pages/order_histogram/order_histogram.vue'], resolve)
});

Vue.component('booster-pack', function (resolve) {
  require(['../components/booster_pack.vue'], resolve)
});

Vue.filter('replace', function (value, regexp, replaced = '') {
  if (!value) return '';
  return value.replace(regexp, replaced);
});

function fetch_accounts() {
  return fetch('/accounts', { credentials: 'same-origin' })
    .then(response => response.json())
    .then(accounts => this.accounts = accounts);
}

function asf_command(account, command) {
  const fetch_options = {
    method: 'post',
    credentials: 'same-origin',
    body: JSON.stringify({
      id: account.id,
      command: command,
    }),
    headers: {
      'content-type': 'application/json'
    }
  };
  const fetch_function = () => fetch('/accounts/asf', fetch_options).then(() => this.drawer.active = false);
  this.on_confirm({
    title: `confirm to send command "${command}" of ${account.bot_name} to ASF?`,
    callback: wrap_fetch(fetch_function, false).bind(this),
  });
}

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#vue-app',
    data: () => ({
      appid: null,
      accounts: [],
      snackbar: {
        active: false,
        message: null,
      },
      confirm: {
        title: null,
        active: false,
        callback: _.noop,
      },
      drawer: {
        active: false,
        accounts_enabled: true,
      },
      modal: {
        active: false,
      },
    }),
    computed: {
      enabled_accounts: function () {
        return _.filter(this.accounts, { status: 'enabled' });
      }
    },
    methods: {
      fetch_accounts: wrap_fetch(fetch_accounts),
      on_confirm: function ({ title, callback }) {
        if (confirm(title)) {
          callback();
        }
      },
      on_message: function ({ message }) {
        this.snackbar = {
          message,
          active: true,
        };
      },
      on_modal: function (data) {
        this.modal = {
          ...data,
          active: true,
        };
      },
      asf_command,
    },
    created() {
      this.fetch_accounts();
    }
  });
});
