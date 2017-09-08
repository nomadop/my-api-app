/**
 * Created by twer on 2017/9/6.
 */

import Vue from 'vue/dist/vue.esm'
import notie from 'notie';

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
        return fetch('/booster_creators/creatable')
            .then(response => response.json())
            .then(booster_creators => app.booster_creators = booster_creators)
            .then(() => app.fetching = false);
      },
      create_and_sell: booster_creator => notie.confirm({
        text: `confirm to create ${booster_creator.name}?`,
        submitCallback: () => fetch('/booster_creators/create_and_sell', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ appid: booster_creator.appid }),
        }).then(() => notie.alert({
          type: 'success',
          text: 'success',
        })).catch(error => notie.alert({
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
