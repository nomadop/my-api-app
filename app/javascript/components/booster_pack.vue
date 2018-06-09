<template>
    <div id="booster-pack">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="type" md-sort-order="desc">
            <md-table-toolbar class="md-large md-elevation-2">
                <div class="md-toolbar-row">
                    <div class="md-toolbar-section-start">
                        <md-button class="md-raised md-primary"
                                   @click="fetch_booster_pack"
                                   :disabled="fetching">
                            Refresh
                        </md-button>
                        <span class="md-title">{{appid}} {{name}}</span>
                    </div>

                    <div class="md-toolbar-section-end">
                        <md-field class="type-selector" md-clearable>
                            <label>Type</label>
                            <md-select v-model="filter.type">
                                <md-option value="Booster Pack">Booster Pack</md-option>
                                <md-option value="[^Foil] Trading Card">Trading Card</md-option>
                                <md-option value="Foil Trading Card">Foil Trading Card</md-option>
                                <md-option value="Emoticon">Emoticon</md-option>
                                <md-option value="Background">Background</md-option>
                            </md-select>
                        </md-field>
                    </div>
                </div>

                <div class="md-toolbar-row md-toolbar-offset">
                    <md-content>
                        <span class="md-subheading">Cost</span>
                        <span class="md-body-1">{{price}}</span>
                    </md-content>
                    <md-content>
                        <span class="md-subheading">Base</span>
                        <span class="md-body-1">{{base_price}}</span>
                    </md-content>
                    <md-content>
                        <span class="md-subheading">Count</span>
                        <span class="md-body-1">{{items.length}}</span>
                    </md-content>
                    <md-content v-if="filter.type !== ''">
                        <span class="md-subheading">Total</span>
                        <span class="md-body-1">{{total_price}}({{total_price_exclude_vat}})</span>
                    </md-content>
                    <md-content v-if="filter.type !== ''">
                        <span class="md-subheading">Avarage</span>
                        <span class="md-body-1">{{avg_price}}({{avg_price_exclude_vat}})</span>
                    </md-content>
                </div>
            </md-table-toolbar>

            <md-table-row slot="md-table-row" slot-scope="{ item }">
                <md-table-cell md-label="Name / Type" class="type-cell" md-sort-by="type">
                    <div class="md-list-item-text">
                     <span>{{item.market_name}}</span>
                     <span>{{item.type}}</span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Price" class="numeric-cell" md-sort-by="lowest_sell_order_exclude_vat" numeric>
                    <color-text color_class="text-primary"
                                :content="item.lowest_sell_order_exclude_vat"
                                :condition="content => content > avg_price"/>
                </md-table-cell>
                <md-table-cell md-label="L/I" class="count-cell">
                    <color-text color_class="text-primary"
                                :content="item.listing_count"
                                :condition="content => content === 0"/>
                    /
                    <color-text color_class="text-danger"
                                :content="item.inventory_count"
                                :condition="content => content >= 1"/>
                </md-table-cell>
            </md-table-row>
        </md-table>
    </div>
</template>

<script>
  import * as _ from 'lodash';

  import ColorText from './color_text.vue';
  import { wrap_fetch } from '../utilities/wrapper';

  function fetch_booster_pack() {
    return fetch(`/booster_creators/detail?appid=${this.appid}`)
      .then(response => response.json())
      .then(detail => {
        this.market_assets = detail.market_assets;
        this.types = _.uniq(_.map(this.market_assets, 'type'));
        this.on_filter();
      });
  }

  function on_filter(filter = {}) {
    const filters = { ...this.filter, ...filter };
    this.items = this.market_assets;
    if (filters.type !== '') {
      const regexp = new RegExp(filters.type);
      this.items = this.items.filter(item => regexp.test(item.type));
    }
  }

  export default {
    props: ['appid', 'name', 'price'],
    data: () => ({
      types: [],
      items: [],
      market_assets: [],
      fetching: false,
      filter: {
        type: '',
      },
    }),
    components: {
      ColorText,
    },
    computed: {
      base_price: function() {
        return _.round(this.price / 3 * 0.6, 2);
      },
      total_price: function() {
        return _.sumBy(this.items, 'lowest_sell_order');
      },
      total_price_exclude_vat: function() {
        return _.sumBy(this.items, 'lowest_sell_order_exclude_vat');
      },
      avg_price: function() {
        return _.round(this.total_price / this.items.length, 2);
      },
      avg_price_exclude_vat: function() {
        return _.round(this.total_price_exclude_vat / this.items.length, 2);
      },
    },
    watch: {
      'filter.type': function (type) {
        this.on_filter({ type });
      },
    },
    methods: {
      fetch_booster_pack: wrap_fetch(fetch_booster_pack),
      on_filter,
    },
  }
</script>

<style scoped>
    .name-cell {
        width: 240px;
    }
    .name-cell >>> .md-table-cell-container {
        width: 240px;
    }

    .numeric-cell {
        width: 100px;
    }
    .numeric-cell >>> .md-table-cell-container {
        width: 100px;
    }

    #booster-pack {
        width: 960px;
    }

    .md-content {
        width: 150px;
    }

    .type-selector {
        max-width: 150px;
    }

    .md-subheading {
        display: block;
    }
</style>
