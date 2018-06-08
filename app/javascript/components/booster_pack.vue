<template>
    <div id="booster-pack">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="type" md-sort-order="desc">
            <md-table-toolbar class="md-elevation-2">
                <div class="md-toolbar-section-start">
                    <md-button class="md-raised md-primary"
                               @click="fetch_booster_pack"
                               :disabled="fetching">
                        Refresh
                    </md-button>
                    <span class="md-title">Appid: {{appid}} Name: {{name}} Cost: {{price}}</span>
                </div>

                <div class="md-toolbar-section-end">
                    <md-field md-clearable>
                        <label>Type</label>
                        <md-select v-model="filter.type" :disabled="types.length === 0">
                            <md-option v-for="type in types" :value="type">{{type | replace(name + ' ') }}</md-option>
                        </md-select>
                    </md-field>
                </div>
            </md-table-toolbar>
            <md-table-row slot="md-table-row" slot-scope="{ item }">
                <md-table-cell md-label="Name" class="name-cell">{{item.market_name}}</md-table-cell>
                <md-table-cell md-label="Type" class="type-cell" md-sort-by="type">{{item.type}}</md-table-cell>
                <md-table-cell md-label="Price" class="numeric-cell" md-sort-by="lowest_sell_order_exclude_vat" numeric>
                    {{item.lowest_sell_order_exclude_vat}}
                </md-table-cell>
                <md-table-cell md-label="L/I" class="count-cell">
                    {{item.listing_count}} / {{item.inventory_count}}
                </md-table-cell>
            </md-table-row>
        </md-table>
    </div>
</template>

<script>
  import * as _ from 'lodash';
  import { wrap_fetch } from '../utilities/wrapper';

  function fetch_booster_pack() {
    return fetch(`/booster_creators/detail?appid=${this.appid}`)
      .then(response => response.json())
      .then(detail => {
        this.name = detail.name;
        this.price = detail.price;
        this.market_assets = detail.market_assets;
        this.types = _.uniq(_.map(this.market_assets, 'type'));
        this.on_filter();
      });
  }

  function on_filter(filter = {}) {
    const filters = { ...this.filter, ...filter };
    this.items = this.market_assets;
    if (filters.type !== '') {
      this.items = _.filter(this.items, { type: filters.type });
    }
  }

  export default {
    props: ['appid'],
    data: () => ({
      name: 'name',
      price: null,
      types: [],
      items: [],
      market_assets: [],
      fetching: false,
      filter: {
        type: '',
      },
    }),
    watch: {
      'filter.type': function (type) {
        this.on_filter({ type });
      },
      'appid': function (appid) {
        if (appid) {
            this.fetch_booster_pack();
        }
      }
    },
    methods: {
      fetch_booster_pack: wrap_fetch(fetch_booster_pack),
      on_filter,
    },
  }
</script>

<style scoped>
    #booster-pack {
        width: 960px;
    }
</style>