import { wrap_fetch } from '../../utilities/wrapper';

function on_response(response) {
  return response.json().then(my_listings => {
    this.my_listings = my_listings;
    this.on_filter();
  })
}

function fetch_all() {
  return fetch('/my_listings/list', { credentials: 'same-origin' }).then(on_response.bind(this));
}

function reload_all() {
  return fetch('/my_listings/reload', { method: 'post', credentials: 'same-origin' }).then(on_response.bind(this));
}

function reload_confirming() {
  return fetch('/my_listings/reload_confirming', { method: 'post', credentials: 'same-origin' }).then(on_response.bind(this));
}

function cancel_selected() {
  this.$emit('confirm', {
    title: `confirm to cancel ${this.selected.length} listings?`,
    callback: wrap_fetch(() => fetch('/my_listings/cancel', {
      method: 'post',
      credentials: 'same-origin',
      body: JSON.stringify({
        ids: this.selected.map(item => item.id),
      }),
      headers: {
        'content-type': 'application/json'
      }
    }).then(() => window.location.reload(true))).bind(this),
  });
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
  if (filters.account !== '') {
    this.items = this.items.filter(item => item.bot_name === filters.account);
  }
  if (filters.confirming !== '') {
    this.items = this.items.filter(item => item.confirming === filters.confirming);
  }
}

export default {
  props: ['accounts'],
  data: () => ({
    items: [],
    selected: [],
    my_listings: [],
    fetching: false,
    filter: {
      account: '',
      confirming: false,
    },
  }),
  watch: {
    'filter.account': function (account) {
      this.on_filter({ account });
    },
    'filter.confirming': function (confirming) {
      this.on_filter({ confirming });
    },
  },
  methods: {
    fetch_all: wrap_fetch(fetch_all),
    reload_all: wrap_fetch(reload_all),
    reload_confirming: wrap_fetch(reload_confirming),
    get_class,
    on_select,
    on_filter,
    cancel_selected,
  },
  filters: {
    round: number => number && +number.toFixed(2),
  },
};