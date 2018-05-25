import NProgress from 'nprogress';

function on_response(response) {
  return response.json()
    .then(inventory_assets => {
      this.items = inventory_assets;
      this.inventory_assets = inventory_assets;
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

function get_class(item) {
  if (item === this.selected) {
    return 'md-primary';
  }

  return 'md-default';
}

function on_select(item) {
  this.selected = item;
}

export default {
  data: () => ({
    items: [],
    inventory_assets: [],
    fetching: false,
    selected: null,
    snackbar: {
      active: false,
      message: null,
    },
    filter: {
      marketable: "",
    }
  }),
  watch: {
    'filter.marketable': function(marketable) {
      if (marketable === "") {
        return this.items = this.inventory_assets;
      }

      this.items = this.inventory_assets.filter(asset => asset.marketable === marketable);
    }
  },
  methods: {
    fetch_assets,
    reload_assets,
    get_class,
    on_select,
  },
  beforeMount() {
    console.log(this);
    this.fetch_assets();
  }
};