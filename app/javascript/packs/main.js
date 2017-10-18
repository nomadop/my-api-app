import Vue from 'vue/dist/vue.esm';
import VModal from 'vue-js-modal';
import VueBeauty from 'vue-beauty';

Vue.use(VModal);
Vue.use(VueBeauty);

Vue.component('booster-creators', function (resolve) {
  require(['../pages/booster_creators.vue'], resolve)
});

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#vue-app',
  });
});
