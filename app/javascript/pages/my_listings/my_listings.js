import NProgress from 'nprogress';

function on_response(response) {
  return response.json()
    .then(my_listings => {
      this.my_listings = my_listings;
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

function fetch_all() {
  if (this.fetching) {
    return;
  }

  this.fetching = true;
  NProgress.start();
  return fetch('/my_listings/list').then(on_response.bind(this));
}

function reload_all() {
  if (this.fetching) {
    return;
  }

  this.fetching = true;
  NProgress.start();
  return fetch('/my_listings/reload', { method: 'post' }).then(on_response.bind(this));
}

function get_class() {
  return 'md-default';
}

function on_select(items) {
  this.selected = items;
}

function on_filter(filter = {}) {
  const filters = { ...this.filter, ...filter };
  this.items = this.my_listings;
  if (filters.confirming !== '') {
    this.items = this.items.filter(item => item.confirming === filters.confirming);
  }
}

export default {
  data: () => ({
    items: [],
    selected: [],
    my_listings: [],
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
      confirming: false,
    },
  }),
  watch: {
    'filter.confirming': function (confirming) {
      this.on_filter({ confirming });
    },
  },
  methods: {
    fetch_all,
    reload_all,
    get_class,
    on_select,
    on_filter,
  },
  filters: {
    round: number => number && +number.toFixed(2),
  },
  beforeMount() {
    console.log(this);
    this.fetch_all();
  }
};