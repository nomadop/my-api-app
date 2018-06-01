import { wrap_fetch } from '../../utilities/wrapper';

function on_response(response) {
  return response.json().then(account_histories => {
    this.account_histories = account_histories;
    this.on_filter();
  })
}

function fetch_all() {
  return fetch('/account_histories/all').then(on_response.bind(this));
}

function reload_all() {
  return fetch('/account_histories/reload', { method: 'post' }).then(on_response.bind(this));
}

function get_class() {
  return 'md-default';
}

function on_select(items) {
  this.selected = items;
}

function on_filter(filter = {}) {
  const filters = { ...this.filter, ...filter };
  this.items = this.account_histories;
  if (filters.account !== '') {
    this.items = this.items.filter(item => item.bot_name === filters.account);
  }
}

export default {
  props: ['accounts'],
  data: () => ({
    items: [],
    selected: [],
    account_histories: [],
    fetching: false,
    filter: {
      confirming: false,
    },
  }),
  watch: {
    'filter.account': function (account) {
      this.on_filter({ account })
    },
  },
  methods: {
    fetch_all: wrap_fetch(fetch_all),
    reload_all: wrap_fetch(reload_all),
    get_class,
    on_select,
    on_filter,
  },
};