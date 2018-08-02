import * as _ from 'lodash';
import Chart from 'chart.js';

import { wrap_fetch } from '../../utilities/wrapper';

Chart.defaults.global.defaultFontColor = 'rgba(255, 255, 255, .7)';

function map_graph_to_line_data(graph) {
  return { x: graph[0], y: graph[1], label: graph[2] }
}

function on_response(response) {
  return response.json().then(order_histogram => {
    const buy_order_data = order_histogram.buy_order_graph.map(map_graph_to_line_data);
    const sell_order_data = order_histogram.sell_order_graph.map(map_graph_to_line_data);
    this.chart = new Chart(this.$refs.canvas, {
      type: 'scatter',
      data: {
        datasets: [{
          label: 'Buy Order',
          fill: 'start',
          showLine: true,
          borderWidth: 2,
          pointRadius: 0,
          borderColor: 'rgba(104, 138, 185, 1)',
          backgroundColor: 'rgba(41, 55, 76, .3)',
          data: buy_order_data,
        }, {
          label: 'Sell Order',
          fill: 'start',
          showLine: true,
          borderWidth: 2,
          pointRadius: 0,
          borderColor: 'rgba(105, 142, 67, 1)',
          backgroundColor: 'rgba(39, 55, 37, .3)',
          data: sell_order_data,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        layout: {
          padding: {
            left: 10,
            right: 10,
          },
        },
        tooltips: {
          mode: 'nearest',
          intersect: false,
          callbacks: {
            label: (item, data) => data.datasets[item.datasetIndex].data[item.index].label,
          }
        },
        hover: {
          mode: 'nearest',
          intersect: false,
        },
        scales: {
          xAxes: [{
            type: 'linear',
            display: true,
            position: 'bottom',
            ticks: {
              stepSize: 0.01,
              maxTicksLimit: 15,
              callback: value => `￥${value.toFixed(2)}`,
            }
          }],
        }
      }
    });
  });
}

function fetch_order_histogram() {
  return fetch(`/order_histograms/${this.item_nameid}/json`, { credentials: 'same-origin' }).then(on_response.bind(this));
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
  }
};