import * as _ from 'lodash';
import { wrap_fetch } from '../../utilities/wrapper';

function on_response(response) {
  return response.json().then(account_histories => {
    this.account_histories = account_histories;
    this.on_filter();
  })
}

function fetch_all() {
  const params = new URLSearchParams();
  params.append('from_date', this.from_date.getTime() / 1000);
  params.append('include_market', this.include_market);
  return fetch(`/account_histories/all?${params}`).then(on_response.bind(this));
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
  if (filters.type !== '') {
    this.items = this.items.filter(item => _.startsWith(item.type, filters.type));
  }
  if (filters.payment !== '') {
    this.items = this.items.filter(item => item.payment.match(filters.payment));
  }
  if (filters.account !== '') {
    this.items = this.items.filter(item => item.account.bot_name === filters.account);
  }
}

function get_initial_from_date() {
  const date = new Date();
  date.setHours(0, 0, 0, 0);
  date.setTime(date.getTime() - 1000 * 60 * 60 * 24 * 14);
  return date;
}

export default {
  props: ['accounts'],
  data: () => ({
    items: [],
    selected: [],
    account_histories: [],
    fetching: false,
    filter: {
      type: '',
      payment: '',
      account: '',
    },
    from_date: get_initial_from_date(),
    include_market: false,
  }),
  watch: {
    'filter.type': function (type) {
      this.on_filter({ type })
    },
    'filter.payment': function (payment) {
      this.on_filter({ payment })
    },
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