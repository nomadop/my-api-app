/**
 * Created by twer on 2017/9/6.
 */

import Vue from 'vue/dist/vue.esm'
import Notie from 'notie';
import NProgress from 'nprogress';

import ColorText from '../components/color_text.vue';

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#booster-creator',
    data: {
      base_ppg: 0.57,
      booster_creators: [],
      fetching: false,
    },
    methods: {
      fetch_creatable: () => {
        app.fetching = true;
        NProgress.start();
        return fetch('/booster_creators/creatable')
            .then(response => response.json())
            .then(booster_creators => app.booster_creators = booster_creators)
            .then(() => {
              app.fetching = false;
              NProgress.done();
            })
            .catch(error => Notie.alert({
              type: 'error',
              text: error,
            }));
      },
      create_and_sell: booster_creator => Notie.confirm({
        text: `confirm to create ${booster_creator.name}?`,
        submitCallback: () => fetch('/booster_creators/create_and_sell', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ appid: booster_creator.appid }),
        }).then(() => Notie.alert({
          type: 'success',
          text: 'success',
        })).catch(error => Notie.alert({
          type: 'error',
          text: error,
        }))
      }),
    },
    components: {
      ColorText,
    }
  });
});
