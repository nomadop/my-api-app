import NProgress from 'nprogress';

function on_response(response) {
  return response.json()
    .then(inventory_assets => {
      this.inventory_assets = inventory_assets;
      this.on_filter();
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

  this.confirm = {
    active: true,
    title: `confirm to sell ${this.selected.length} items by ppg ${this.sell_ppg}?`,
    callback: () => {
      this.fetching = true;
      NProgress.start();
      const option = {
        method: 'post',
        body: JSON.stringify({
          sell_ppg: this.sell_ppg,
          asset_ids: this.selected.map(item => item.id),
        }),
        headers: {
          'content-type': 'application/json'
        }
      };
      return fetch('/inventory/sell_by_ppg', option)
        .then(() => window.location.reload(true))
        .catch(error => {
          this.fetching = false;
          NProgress.done();
          this.snackbar = {
            type: 'error',
            active: true,
            message: error,
          };
        });
    }
  };
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
  this.items = this.inventory_assets;
  if (filters.marketable !== '') {
    this.items = this.items.filter(item => item.marketable === filters.marketable);
  }
  if (filters.sell_ppg !== '') {
    this.items = this.items.filter(item => item.price_per_goo_exclude_vat >= +filters.sell_ppg);
  }
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
    confirm: {
      title: null,
      active: false,
      callback: () => {},
    },
    filter: {
      marketable: 1,
      sell_ppg: '',
    },
    sell_ppg: 0.57,
  }),
  watch: {
    'filter.marketable': function (marketable) {
      this.on_filter({ marketable });
    },
    'filter.sell_ppg': function (sell_ppg) {
      this.on_filter({ sell_ppg })
    },
  },
  methods: {
    fetch_assets,
    reload_assets,
    sell_by_ppg,
    get_class,
    on_select,
    on_filter,
  },
  filters: {
    round: number => number && +number.toFixed(2),
  },
  beforeMount() {
    console.log(this);
    this.fetch_assets();
  }
};