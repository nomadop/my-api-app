import NProgress from 'nprogress';

function fetch_assets() {
  if (this.fetching) {
    return;
  }

  this.fetching = true;
  NProgress.start();
  return fetch('/inventory/assets')
    .then(response => response.json())
    .then(inventory_assets => this.inventory_assets = inventory_assets)
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
    inventory_assets: [],
    fetching: false,
    selected: null,
    snackbar: {
      active: false,
      message: null,
    },
  }),
  methods: {
    fetch_assets,
    get_class,
    on_select,
  },
  beforeMount() {
    this.fetch_assets();
  }
};