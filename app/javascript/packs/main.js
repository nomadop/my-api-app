import Vue from 'vue/dist/vue.esm';
import VueMaterial from 'vue-material';

Vue.use(VueMaterial);

Vue.component('booster-creators', function (resolve) {
  require(['../pages/booster_creators/booster_creators.vue'], resolve)
});

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#vue-app',
  });
});
