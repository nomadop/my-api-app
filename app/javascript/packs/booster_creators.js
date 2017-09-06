/**
 * Created by twer on 2017/9/6.
 */

import Vue from 'vue/dist/vue.esm'

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#creatable',
    data: {
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
    }
  });
});