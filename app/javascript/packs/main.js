import Vue from 'vue/dist/vue.esm';

Vue.component('booster-creators', function (resolve) {
  require(['../pages/booster_creators/booster_creators.vue'], resolve)
});

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#vue-app',
  });
});
