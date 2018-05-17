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
    .catch(error => this.snackbar = {
      type: 'error',
      active: true,
      message: error,
    });
}

function create_and_sell(booster_creator) {
  return Notie.confirm({
    text: `confirm to create ${booster_creator.name}?`,
    submitCallback: () => fetch('/booster_creators/create_and_sell', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ appid: booster_creator.appid }),
    }).then(() => this.snackbar = {
      type: 'info',
      active: true,
      message: 'success',
    }).catch(error => this.snackbar = {
      type: 'error',
      active: true,
      message: error,
    })
  });
}

function create_and_unpack(booster_creator) {
  return Notie.confirm({
    text: `confirm to create ${booster_creator.name}?`,
    submitCallback: () => fetch('/booster_creators/create_and_unpack', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ appid: booster_creator.appid }),
    }).then(() => this.snackbar = {
      type: 'info',
      active: true,
      message: 'success',
    }).catch(error => this.snackbar = {
      type: 'error',
      active: true,
      message: error,
    })
  });
}

function sell_all_assets(booster_creator) {
  return Notie.confirm({
    text: `confirm to create ${booster_creator.name}?`,
    submitCallback: () => fetch('/booster_creators/sell_all_assets', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ appid: booster_creator.appid }),
    }).then(() => this.snackbar = {
      type: 'info',
      active: true,
      message: 'success',
    }).catch(error => this.snackbar = {
      type: 'error',
      active: true,
      message: error,
    })
  });
}

function open_booster_creator_model(booster_creator) {
  this.$modal.show('booster-creator', { booster_creator });
}

function get_class(item) {
  if (item === this.selected) {
    return 'md-primary';
  }

  if (item.min_available_time) {
    return 'md-accent';
  }

  return 'md-default';
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
    snackbar: {
      active: false,
      message: null,
    }
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