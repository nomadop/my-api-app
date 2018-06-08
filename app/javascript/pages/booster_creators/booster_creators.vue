<template>
    <div id="booster-creators">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="open_price_per_goo" md-sort-order="desc">
            <md-table-toolbar class="md-elevation-2">
                <md-badge class="md-primary" :md-content="items.length" />
                <div class="md-toolbar-section-start">
                    <md-button class="md-raised md-primary"
                               @click="fetch_creatable(false)"
                               :disabled="fetching || base_ppg === ''">
                        Load
                    </md-button>
                    <md-button class="md-raised md-primary"
                               @click="fetch_creatable(true)"
                               :disabled="fetching || base_ppg === ''">
                        Reload
                    </md-button>
                    <md-field>
                        <label>Base PPG</label>
                        <md-input v-model="base_ppg"></md-input>
                    </md-field>
                </div>

                <div class="md-toolbar-section-end">
                    <md-field class="account-selector" md-clearable>
                        <label>Account</label>
                        <md-select v-model="filter.account" :disabled="account_names.length === 0">
                            <md-option v-for="name in account_names" :value="name">{{name}}</md-option>
                        </md-select>
                    </md-field>

                    <md-field md-clearable>
                        <label>Available</label>
                        <md-select v-model="filter.available">
                            <md-option :value="true">True</md-option>
                            <md-option :value="false">False</md-option>
                        </md-select>
                    </md-field>
                </div>
            </md-table-toolbar>
            <md-table-row slot="md-table-row" slot-scope="{ item }" :class="get_class(item)">
                <md-table-cell md-label="Name" class="name-cell">
                    <div class="md-list-item-text">
                        <span>{{item.name}}</span>
                        <span>Appid: {{item.appid}} | Cost: {{item.price}} | Foil: {{item.open_price.foil_average}}</span>
                        <span v-if="item.available_time">
                            Available At:
                            <color-text color_class="text-primary"
                                        :content="item.available_time ? new Date(item.available_time) : null"
                                        :condition="content => content < new Date()"
                                        :filter="content => content ? content.toLocaleString() : null"/>
                        </span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="PPG"  class="ppg-cell" md-sort-by="price_per_goo" md-numeric>
                    <div class="md-list-item-text">
                        <color-text color_class="text-primary"
                                    :content="item.price_per_goo"
                                    :condition="content => content > 0.57"/>
                        <color-text color_class="text-danger"
                                    :content="item.sell_proportion"
                                    :condition="content => content < 0.1"/>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Open PPG" class="open-ppg-cell" md-sort-by="open_price_per_goo" md-numeric>
                    <div class="md-list-item-text">
                        <color-text color_class="text-primary"
                                    :content="item.open_price_per_goo"
                                    :condition="content => content > base_ppg"/>
                        <color-text color_class="text-danger"
                                    :content="item.trading_card_prices_proportion"
                                    :condition="content => content < 0.1"/>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="COV/OBR" class="open-cov-cell" md-sort-by="open_price.coefficient_of_variation" md-numeric>
                    <div class="md-list-item-text">
                        <color-text color_class="text-primary"
                                    :content="item.open_price.coefficient_of_variation"
                                    :condition="content => content < 0.5"/>
                        <color-text color_class="text-primary"
                                    :content="item.open_price.over_baseline_rate"
                                    :condition="content => content > 0.5"/>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="L/I" class="li-count-cell">
                    <div class="md-list-item-text">
                        <span>
                            <color-text color_class="text-primary"
                                        :content="item.listing_booster_pack_count"
                                        :condition="content => content === 0 && item.price_per_goo > 0.57"/>
                            /
                            <color-text color_class="text-danger"
                                        :content="item.inventory_assets_count"
                                        :condition="content => content >= 1"/>
                        </span>
                        <span>{{item.sell_order_count}} / {{item.buy_order_count}}</span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Open L/I" class="li-count-cell">
                    <div class="md-list-item-text">
                        <span>
                            <color-text color_class="text-primary"
                                        :content="item.listing_trading_card_count"
                                        :condition="content => content < 5"/>
                            /
                            <color-text color_class="text-danger"
                                        :content="item.inventory_cards_count"
                                        :condition="content => content >= 3"/>
                        </span>
                        <span>{{item.open_sell_order_count}} / {{item.open_buy_order_count}}</span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Actions" class="action-cell">
                    <md-button class="md-dense md-icon-button" @click="create_and_unpack(item)" :disabled="item.account_booster_creators.length === 0">
                        <md-icon>unarchive</md-icon>
                    </md-button>
                    <md-button class="md-dense md-icon-button" @click="create_and_sell(item)" :disabled="item.account_booster_creators.length === 0">
                        <md-icon>shop</md-icon>
                    </md-button>
                    <md-button class="md-dense md-icon-button" @click="sell_all_assets(item)" :disabled="item.account_booster_creators.length === 0">
                        <md-icon>shop_two</md-icon>
                    </md-button>
                </md-table-cell>
            </md-table-row>
        </md-table>
    </div>
</template>

<style scoped>
    .ppg-cell {
        width: 64px;
    }
    .ppg-cell >>> .md-table-cell-container {
        width: 64px;
    }

    .open-ppg-cell {
        width: 90px;
    }
    .open-ppg-cell >>> .md-table-cell-container {
        width: 90px;
    }

    .open-cov-cell {
        width: 90px;
    }
    .open-cov-cell >>> .md-table-cell-container  {
        width: 90px;
    }

    .li-count-cell {
        width: 100px;
    }
    .li-count-cell >>> .md-table-cell-container {
        width: 100px;
    }

    .action-cell {
        width: 176px;
    }
    .action-cell >>> .md-table-cell-container {
        width: 176px;
        font-size: 0;
    }
</style>

<script src="./booster_creators.js"></script>
