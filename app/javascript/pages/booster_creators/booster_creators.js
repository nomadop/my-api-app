import * as _ from 'lodash';

import ColorText from '../../components/color_text.vue';
import { wrap_fetch } from '../../utilities/wrapper';

function fetch_creatable(refresh = true) {
  return fetch(`/booster_creators/creatable?base_ppg=${+this.base_ppg}${refresh ? '&refresh=1' : ''}`, { credentials: 'same-origin' })
    .then(response => response.json())
    .then(booster_creators => {
      this.booster_creators = booster_creators;
      this.account_names = booster_creators.reduce(
        (names, booster_creator) => _.union(
          names, _.map(booster_creator.account_booster_creators, 'bot_name')
        ), ['None']
      ).sort();
      this.on_filter();
    });
}

function create_and_sell(booster_creator) {
  this.$emit('confirm', {
    title: `confirm to create and sell ${booster_creator.name}?`,
    callback: wrap_fetch(() => fetch('/booster_creators/create_and_sell', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ appid: booster_creator.appid, bot_name: this.filter.account }),
    })).bind(this),
  });
}

function create_and_unpack(booster_creator) {
  this.$emit('confirm', {
    title: `confirm to create and unpack ${booster_creator.name}?`,
    callback: wrap_fetch(() => fetch('/booster_creators/create_and_unpack', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ appid: booster_creator.appid, bot_name: this.filter.account }),
    })).bind(this),
  });
}

function sell_all_assets(booster_creator) {
  this.$emit('confirm', {
    title: `confirm to sell all assets of ${booster_creator.name}?`,
    callback: wrap_fetch(() => fetch('/booster_creators/sell_all_assets', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ appid: booster_creator.appid, bot_name: this.filter.account }),
    })).bind(this),
  });
}

function get_class(item) {
  if (item === this.selected) {
    return 'md-primary';
  }

  if (item.available_time) {
    return 'md-accent';
  }

  return 'md-default';
}

function on_select(item) {
  this.selected = item;
}

function on_filter(filter = {}) {
  const filters = { ...this.filter, ...filter };
  this.items = this.booster_creators;
  if (filters.account === 'None') {
    this.items = this.items.filter(item => _.isEmpty(item.account_booster_creators));
  } else if (filters.account !== '') {
    this.items = this.items.filter(item => _.some(item.account_booster_creators, { bot_name: filters.account }));
  }
  this.set_available_time(filters.account);
  if (filters.available !== '') {
    this.items = this.items.filter(item => _.isNil(item.available_time) === filters.available);
  }
}

function get_available_time(booster_creator, account) {
  if (_.isEmpty(booster_creator.account_booster_creators)) {
    return null;
  }

  if (account === '') {
    return booster_creator.min_available_time;
  }

  return _.get(
    _.find(booster_creator.account_booster_creators, { bot_name: account }), 'available_time'
  );
}

function set_available_time(account) {
  this.items = this.items.map(item => ({
    ...item,
    available_time: get_available_time(item, account),
  }));
}

function open_detail(item) {
  this.$emit('detail', _.pick(item, ['appid', 'name', 'price']));
}

export default {
  data: () => ({
    items: [],
    account_names: [],
    booster_creators: [],
    fetching: false,
    selected: null,
    filter: {
      account: '',
      available: '',
    },
    base_ppg: 0.55,
  }),
  components: {
    ColorText,
  },
  watch: {
    'filter.account': function (account) {
      this.on_filter({ account });
    },
    'filter.available': function (available) {
      this.on_filter({ available });
    },
  },
  methods: {
    fetch_creatable: wrap_fetch(fetch_creatable),
    create_and_sell: create_and_sell,
    create_and_unpack: create_and_unpack,
    sell_all_assets,
    get_class,
    on_select,
    on_filter,
    set_available_time,
    open_detail,
  },
};