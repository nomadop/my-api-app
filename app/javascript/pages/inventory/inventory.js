import * as _ from 'lodash';
import { wrap_fetch } from '../../utilities/wrapper';

function on_response(response) {
  return response.json().then(inventory_assets => {
    this.inventory_assets = inventory_assets;
    this.on_filter();
  });
}

function fetch_assets() {
  return fetch('/inventory/assets').then(on_response.bind(this));
}

function reload_assets() {
  return fetch('/inventory/reload', { method: 'post' }).then(on_response.bind(this));
}

function sell_by_ppg() {
  this.$emit('confirm', {
    title: `confirm to sell ${this.selected.length} items by ppg ${this.sell_ppg}?`,
    callback: wrap_fetch(() => fetch('/inventory/sell_by_ppg', {
      method: 'post',
      body: JSON.stringify({
        sell_ppg: this.sell_ppg,
        asset_ids: this.selected.map(item => item.id),
      }),
      headers: {
        'content-type': 'application/json'
      }
    }).then(() => window.location.reload(true))).bind(this),
  });
}

function grind_into_goo() {
  this.$emit('confirm', {
    title: `confirm to grind ${this.selected.length} items into goo?`,
    callback: wrap_fetch(() => fetch('/inventory/grind_into_goo', {
      method: 'post',
      body: JSON.stringify({
        asset_ids: this.selected.map(item => item.id),
      }),
      headers: {
        'content-type': 'application/json'
      }
    }).then(() => window.location.reload(true))).bind(this),
  });
}

function send_trade_offer() {
  const target_name = _.find(this.accounts, { id: this.selected_account }).bot_name;
  this.$emit('confirm', {
    title: `confirm to trade ${this.selected.length} items to ${target_name}?`,
    callback: wrap_fetch(() => fetch('/inventory/send_trade_offer', {
      method: 'post',
      body: JSON.stringify({
        target: this.selected_account,
        ids: this.selected.map(item => item.id),
      }),
      headers: {
        'content-type': 'application/json'
      }
    }).then(() => window.location.reload(true))).bind(this),
  });
}

function get_class(item) {
  if (item === this.selected) {
    return 'md-primary';
  }

  return 'md-default';
}

function on_select(items) {
  this.selected = items;
}

function on_filter(filter = {}) {
  const filters = { ...this.filter, ...filter };
  this.items = this.inventory_assets.filter(item => item.marketable === (filters.marketable ? 1 : 0));
  if (filters.sell_ppg !== '') {
    this.items = this.items.filter(item => item.price_per_goo_exclude_vat >= +filters.sell_ppg);
  }
  if (filters.account !== '') {
    this.items = this.items.filter(item => item.bot_name === filters.account);
  }
}

export default {
  props: ['accounts'],
  data: () => ({
    items: [],
    selected: [],
    inventory_assets: [],
    fetching: false,
    filter: {
      marketable: true,
      sell_ppg: '',
      account: '',
    },
    sell_ppg: 0.57,
    selected_account: '',
  }),
  watch: {
    'filter.marketable': function (marketable) {
      this.on_filter({ marketable });
    },
    'filter.sell_ppg': function (sell_ppg) {
      this.on_filter({ sell_ppg })
    },
    'filter.account': function (account) {
      this.on_filter({ account })
    },
  },
  methods: {
    fetch_assets: wrap_fetch(fetch_assets),
    reload_assets: wrap_fetch(reload_assets),
    sell_by_ppg,
    send_trade_offer,
    get_class,
    on_select,
    on_filter,
    grind_into_goo,
  },
  filters: {
    round: number => number && +number.toFixed(2),
  },
};