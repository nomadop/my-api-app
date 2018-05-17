import Notie from 'notie';
import NProgress from 'nprogress';

import ColorText from '../../components/color_text.vue';

function fetch_creatable(refresh = true) {
  if (this.fetching) {
    return;
  }

  this.fetching = true;
  NProgress.start();
  return fetch(`/booster_creators/creatable?base_ppg=${this.base_ppg}&limit=${this.limit}${refresh ? '&refresh=1' : ''}`)
    .then(response => response.json())
    .then(booster_creators => this.booster_creators = booster_creators)
    .then(() => {
      this.fetching = false;
      NProgress.done();
    })
    .catch(error => Notie.alert({
      type: 'error',
      text: error,
    }));
}

function create_and_sell(booster_creator) {
  return Notie.confirm({
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
  });
}

function create_and_unpack(booster_creator) {
  return Notie.confirm({
    text: `confirm to create ${booster_creator.name}?`,
    submitCallback: () => fetch('/booster_creators/create_and_unpack', {
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
  });
}

function sell_all_assets(booster_creator) {
  return Notie.confirm({
    text: `confirm to create ${booster_creator.name}?`,
    submitCallback: () => fetch('/booster_creators/sell_all_assets', {
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
  });
}

function open_booster_creator_model(booster_creator) {
  this.$modal.show('booster-creator', { booster_creator });
}

function get_class(item) {
  return item === this.selected ? 'md-primary' : 'md-default';
}

function on_select(item) {
  this.selected = item;
}

export default {
  props: ['base_ppg', 'limit'],
  data: () => ({
    booster_creators: [],
    fetching: false,
    selected: null,
  }),
  components: {
    ColorText,
  },
  methods: {
    fetch_creatable,
    create_and_sell,
    create_and_unpack,
    sell_all_assets,
    open_booster_creator_model,
    get_class,
    on_select,
  },
  beforeMount() {
    this.fetch_creatable(false);
  }
};