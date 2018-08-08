import * as _ from 'lodash';
import Chart from 'chart.js';

import { wrap_fetch } from '../../utilities/wrapper';

const common_dataset_option = {
  showLine: true,
  borderWidth: 2,
};

function map_graph_to_line_data(graph) {
  return { x: graph[0], y: graph[1], label: graph[2] }
}

function on_order_histogram_response(response) {
  return response.json().then(order_histogram => {
    const buy_order_data = order_histogram.buy_order_graph.map(map_graph_to_line_data);
    const sell_order_data = order_histogram.sell_order_graph.map(map_graph_to_line_data);
    this.order_chart.data.datasets[0] = {
      ...common_dataset_option,
      fill: 'start',
      label: 'Buy Order',
      pointRadius: 0,
      borderColor: 'rgba(104, 138, 185, 1)',
      backgroundColor: 'rgba(41, 55, 76, .3)',
      data: buy_order_data,
    };
    this.order_chart.data.datasets[1] = {
      ...common_dataset_option,
      fill: 'start',
      label: 'Sell Order',
      pointRadius: 0,
      borderColor: 'rgba(105, 142, 67, 1)',
      backgroundColor: 'rgba(39, 55, 37, .3)',
      data: sell_order_data,
    };
    this.order_chart.update();
  });
}

function on_history_response(response) {
  return response.json().then(histories => {
    const buy_history_data = histories.map(history => ({ x: history.created_at, y: history.highest_buy_order }));
    const sell_history_data = histories.map(history => ({ x: history.created_at, y: history.lowest_sell_order }));
    this.history_chart.data.datasets[0] = {
      ...common_dataset_option,
      fill: false,
      label: 'Buy History',
      borderColor: 'rgba(104, 138, 185, 1)',
      data: buy_history_data,
    };
    this.history_chart.data.datasets[1] = {
      ...common_dataset_option,
      fill: false,
      label: 'Sell Order',
      borderColor: 'rgba(105, 142, 67, 1)',
      data: sell_history_data,
    };
    this.history_chart.update();
  });
}

function fetch_order_histogram() {
  return fetch(`/order_histograms/${this.item_nameid}/json`, { credentials: 'same-origin' })
    .then(on_order_histogram_response.bind(this));
}

function fetch_history() {
  return fetch(`/order_histograms/${this.item_nameid}/history`, { credentials: 'same-origin' })
    .then(on_history_response.bind(this));
}

function get_tooltip_label(item, data) {
  return data.datasets[item.datasetIndex].data[item.index].label;
}

export default {
  props: ['item_nameid'],
  data: () => ({}),
  watch: {
  },
  methods: {
    fetch_order_histogram: wrap_fetch(fetch_order_histogram, false),
    fetch_history: wrap_fetch(fetch_history, false),
  },
  created() {
    this.fetch_order_histogram();
    this.fetch_history();
  },
  mounted() {
    this.order_chart = new Chart(this.$refs.order_chart, {
      type: 'scatter',
      data: { datasets: [] },
      options: {
        tooltips: {
          callbacks: { label: get_tooltip_label },
        },
        hover: { mode: 'nearest', intersect: false },
        scales: {
          xAxes: [{
            type: 'linear',
            ticks: {
              stepSize: 0.01,
              maxTicksLimit: 15,
              callback: value => `￥${value.toFixed(2)}`,
            }
          }],
        }
      }
    });
    this.history_chart = new Chart(this.$refs.history_chart, {
      type: 'scatter',
      data: { datasets: [] },
      options: {
        hover: { mode: 'nearest', intersect: false },
        scales: {
          xAxes: [{
            type: 'time',
          }],
          yAxes: [{
            ticks: {
              callback: value => `￥${(value / 100).toFixed(2)}`,
            }
          }],
        }
      }
    });
  }
};