import NProgress from 'nprogress';

function on_response(response) {
  return response.json()
    .then(inventory_assets => {
      this.inventory_assets = inventory_assets;
      this.filter_by_marketable(this.filter.marketable);
    })
    .then(() => {
      this.fetching = false;
      NProgress.done();
    })
    .catch(error => {
      NProgress.done();
      this.fetching = false;
      this.snackbar = {
        type: 'error',
        active: true,
        message: error,
      };
    });
}

function fetch_assets() {
  if (this.fetching) {
    return;
  }

  this.fetching = true;
  NProgress.start();
  return fetch('/inventory/assets').then(on_response.bind(this));
}

function reload_assets() {
  if (this.fetching) {
    return;
  }

  this.fetching = true;
  NProgress.start();
  return fetch('/inventory/reload', { method: 'post' }).then(on_response.bind(this));
}

function sell_by_ppg() {
  if (this.fetching) {
    return;
  }
  this.fetching = true;
  NProgress.start();
  return fetch('/inventory/sell_by_ppg', {
    method: 'post',
    body: JSON.stringify({
      sell_ppg: this.sell_ppg,
      asset_ids: this.selected.map(item => item.id),
    }),
    headers: {
      'content-type': 'application/json'
    },
  }).then(() => window.location.reload(true));
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

function filter_by_marketable(marketable) {
  if (marketable === "") {
    return this.items = this.inventory_assets;
  }

  this.items = this.inventory_assets.filter(asset => asset.marketable === marketable);
}

export default {
  data: () => ({
    items: [],
    selected: [],
    inventory_assets: [],
    fetching: false,
    snackbar: {
      active: false,
      message: null,
    },
    filter: {
      marketable: 1,
    },
    sell_ppg: 0.57,
  }),
  watch: {
    'filter.marketable': function (marketable) {
      this.filter_by_marketable(marketable);
    }
  },
  methods: {
    fetch_assets,
    reload_assets,
    sell_by_ppg,
    get_class,
    on_select,
    filter_by_marketable,
  },
  filters: {
    round: number => number && +number.toFixed(2),
  },
  beforeMount() {
    console.log(this);
    this.fetch_assets();
  }
};