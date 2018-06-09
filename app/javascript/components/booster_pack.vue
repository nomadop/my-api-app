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
                        <span class="md-title">{{appid}} - {{name}}</span>
                    </div>

                    <div class="md-toolbar-section-end">
                        <md-tabs md-active-tab="trading-card" @md-changed="on_tab_change">
                            <md-tab v-for="tab in tabs" :id="tab.id"
                                    :md-icon="tab.icon" :md-label="tab.items.length"></md-tab>
                        </md-tabs>
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
                        <span class="md-subheading">All Base</span>
                        <span class="md-body-1">{{all_base_price}}</span>
                    </md-content>
                    <md-content v-if="items.length > 0">
                        <span class="md-subheading">Total</span>
                        <span class="md-body-1">{{total_price}} ({{total_price_exclude_vat}})</span>
                    </md-content>
                    <md-content v-if="items.length > 0">
                        <span class="md-subheading">Avarage</span>
                        <span class="md-body-1">{{avg_price}} ({{avg_price_exclude_vat}})</span>
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
                <md-table-cell md-label="L/I" class="numeric-cell">
                    <color-text color_class="text-primary"
                                :content="item.listing_count"
                                :condition="content => content === 0"/>
                    /
                    <color-text color_class="text-danger"
                                :content="item.inventory_count"
                                :condition="content => content >= 1"/>
                </md-table-cell>
                <md-table-cell md-label="Actions" class="action-cell">
                    <md-button class="md-dense md-icon-button" :href="item.listing_url" target="_blank">
                        <md-icon>link</md-icon>
                    </md-button>
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
        this.tabs = this.tabs.map(tab => {
          const items = detail.market_assets.filter(item => tab.regexp.test(item.type));
          return { ...tab, items };
        });
      });
  }

  function on_tab_change(id) {
    this.current_tab = id;
  }

  export default {
    props: ['appid', 'name', 'price'],
    data: () => ({
      fetching: false,
      tabs: [
        { id: 'all', icon: 'all_inclusive', items: [], regexp: /./ },
        { id: 'booster-pack', icon: 'photo_album', items: [], regexp: /Booster Pack/ },
        { id: 'trading-card', icon: 'photo', items: [], regexp: /^((?!Foil).)* Trading Card/ },
        { id: 'foil-trading-card', icon: 'photo_filter', items: [], regexp: /Foil Trading Card/ },
        { id: 'emoticon', icon: 'tag_faces', items: [], regexp: /Emoticon/ },
        { id: 'background', icon: 'wallpaper', items: [], regexp: /Background/ },
      ],
      current_tab: 'trading-card',
    }),
    components: {
      ColorText,
    },
    computed: {
      items: function() {
        return _.find(this.tabs, { id: this.current_tab }).items;
      },
      trading_cards: function() {
        return _.find(this.tabs, { id: 'trading-card' }).items;
      },
      base_price: function() {
        return _.round(this.price / 3 * 0.6, 2);
      },
      all_base_price: function () {
        return _.round(this.base_price * this.trading_cards.length, 2);
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
    methods: {
      fetch_booster_pack: wrap_fetch(fetch_booster_pack),
      on_tab_change,
    },
  }
</script>

<style scoped>
    .action-cell {
        width: 100px;
    }
    .action-cell >>> .md-table-cell-container {
        width: 100px;
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

    .md-subheading {
        display: block;
    }

    .md-tabs >>> .md-icon-label {
        height: 48px;
    }

    .md-tabs >>> .md-tab-label {
        top: 0;
        right: 0;
        position: absolute;
    }
</style>
