import * as _ from 'lodash';
import { wrap_fetch } from '../../utilities/wrapper';

const common_dataset_option = {
  fill: false,
  showLine: true,
  borderWidth: 2,
  pointRadius: 0,
};

function reduce_chart_data(data, item) {
  const lastItem = _.last(data);
  if (lastItem && lastItem.formatted_date === item.formatted_date) {
    lastItem.y += item.change;
    return data;
  }

  const date = new Date(Date.parse(item.date));
  return data.concat({ x: date, y: item.change, formatted_date: item.formatted_date });
}

function update_chart() {
  const markets = this.account_histories.filter(item => item.items[0] === 'Steam 社区市场');
  if (_.isEmpty(markets)) { return; }
  const total_data = markets.reduce(reduce_chart_data, []);
  const income_data = markets.filter(item => item.change > 0).reduce(reduce_chart_data, []);
  const expense_data = markets.filter(item => item.change < 0).reduce(reduce_chart_data, []);
  this.chart.data.datasets[0] = {
    ...common_dataset_option,
    label: '收入',
    borderColor: 'rgba(105, 142, 67, 1)',
    data: income_data,
  };
  this.chart.data.datasets[1] = {
    ...common_dataset_option,
    label: '合计',
    borderColor: 'rgba(104, 138, 185, 1)',
    data: total_data,
  };
  this.chart.data.datasets[2] = {
    ...common_dataset_option,
    label: '支出',
    borderColor: 'rgba(229, 57, 53, 1)',
    data: expense_data,
  };
  this.chart.update();
}

function on_response(response) {
  return response.json().then(account_histories => {
    this.account_histories = account_histories;
    this.update_chart();
    this.on_filter();
  });
}

function fetch_all() {
  const params = new URLSearchParams();
  params.append('from_date', this.from_date.getTime() / 1000);
  params.append('include_market', this.include_market);
  return fetch(`/account_histories/all?${params}`, { credentials: 'same-origin' }).then(on_response.bind(this));
}

function reload_all() {
  return fetch('/account_histories/reload', { method: 'post', credentials: 'same-origin' }).then(on_response.bind(this));
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
    include_market: true,
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
    update_chart,
  },
  mounted() {
    this.chart = new Chart(this.$refs.canvas, {
      type: 'scatter',
      data: { datasets: [] },
      options: {
        hover: { mode: 'nearest', intersect: false },
        scales: {
          xAxes: [{
            type: 'time',
            ticks: {
              callback: (value, index, data) => {
                const major = _.get(data, `[${index}].major`, false);
                const date = new Date(_.get(data, `[${index}].value`, 0));
                return major ? `${date.getMonth() + 1}-${date.getDate()}` : '';
              },
            }
          }],
          yAxes: [{
            ticks: {
              callback: value => `￥${(value / 100).toFixed(2)}`,
            }
          }],
        }
      }
    });
  },
};