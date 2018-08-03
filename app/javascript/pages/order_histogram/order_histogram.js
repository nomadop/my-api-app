import * as _ from 'lodash';
import Chart from 'chart.js';

import { wrap_fetch } from '../../utilities/wrapper';

const common_dataset_option = {
  fill: 'start',
  showLine: true,
  borderWidth: 2,
  pointRadius: 0,
};

function map_graph_to_line_data(graph) {
  return { x: graph[0], y: graph[1], label: graph[2] }
}

function on_response(response) {
  return response.json().then(order_histogram => {
    const buy_order_data = order_histogram.buy_order_graph.map(map_graph_to_line_data);
    const sell_order_data = order_histogram.sell_order_graph.map(map_graph_to_line_data);
    this.chart.data.datasets[0] = {
      ...common_dataset_option,
      label: 'Buy Order',
      borderColor: 'rgba(104, 138, 185, 1)',
      backgroundColor: 'rgba(41, 55, 76, .3)',
      data: buy_order_data,
    };
    this.chart.data.datasets[1] = {
      ...common_dataset_option,
      label: 'Sell Order',
      borderColor: 'rgba(105, 142, 67, 1)',
      backgroundColor: 'rgba(39, 55, 37, .3)',
      data: sell_order_data,
    };
    this.chart.update();
  });
}

function fetch_order_histogram() {
  return fetch(`/order_histograms/${this.item_nameid}/json`, { credentials: 'same-origin' }).then(on_response.bind(this));
}

function get_tooltip_label(item, data) {
  return data.datasets[item.datasetIndex].data[item.index].label;
}

export default {
  props: ['item_nameid'],
  data: () => ({
    fetching: false,
  }),
  watch: {
  },
  methods: {
    fetch_order_histogram: wrap_fetch(fetch_order_histogram),
  },
  created() {
    this.fetch_order_histogram();
  },
  mounted() {
    this.chart = new Chart(this.$refs.canvas, {
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
  }
};