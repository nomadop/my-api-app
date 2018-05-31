<template>
    <div id="booster-creators">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="open_price_per_goo" md-sort-order="desc">
            <md-table-toolbar class="md-elevation-2">
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
                    <md-field class="account-filter" md-clearable>
                        <label>Account</label>
                        <md-select v-model="filter.account" :disabled="account_names.length === 0">
                            <md-option v-for="name in account_names" :value="name">{{name}}</md-option>
                        </md-select>
                    </md-field>
                </div>
            </md-table-toolbar>
            <md-table-row slot="md-table-row" slot-scope="{ item }" :class="get_class(item)">
                <md-table-cell md-label="Name" class="name-cell">{{item.name}}</md-table-cell>
                <md-table-cell md-label="PPG"  class="ppg-cell" md-sort-by="price_per_goo" md-numeric>
                    <color-text color_class="text-primary"
                                :content="item.price_per_goo"
                                :condition="content => content > 0.57"/>
                </md-table-cell>
                <md-table-cell md-label="Open PPG" class="open-ppg-cell" md-sort-by="open_price_per_goo" md-numeric>
                    <color-text color_class="text-primary"
                                :content="item.open_price_per_goo"
                                :condition="content => content > base_ppg"/>
                </md-table-cell>
                <md-table-cell md-label="Open COV" class="open-cov-cell" md-sort-by="open_price.coefficient_of_variation" md-numeric>
                    <color-text color_class="text-primary"
                                :content="item.open_price.coefficient_of_variation"
                                :condition="content => content < 0.5"/>
                </md-table-cell>
                <md-table-cell md-label="Open OBR" class="open-obr-cell" md-sort-by="open_price.over_baseline_rate" md-numeric>
                    <color-text color_class="text-primary"
                                :content="item.open_price.over_baseline_rate"
                                :condition="content => content > 0.5"/>
                </md-table-cell>
                <md-table-cell md-label="L/I" class="li-count-cell">
                    <color-text color_class="text-primary"
                                :content="item.listing_booster_pack_count"
                                :condition="content => content === 0 && item.price_per_goo > 0.57"/>
                    /
                    <color-text color_class="text-danger"
                                :content="item.inventory_assets_count"
                                :condition="content => content >= 1"/>
                </md-table-cell>
                <md-table-cell md-label="Open L/I" class="open-li-count-cell">
                    <color-text color_class="text-danger"
                                :content="item.listing_trading_card_count"
                                :condition="content => content >= 5"/>
                    /
                    <color-text color_class="text-danger"
                                :content="item.inventory_cards_count"
                                :condition="content => content >= 3"/>
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
                <md-tooltip md-direction="bottom">
                    <span class="tooltip-label">Appid:</span> {{item.appid}}
                    | <span class="tooltip-label">Price:</span> {{item.price}}
                    | <span class="tooltip-label">AVG Foil Price:</span> {{item.open_price.foil_average}}
                    | <span class="tooltip-label">Order Count:</span> {{item.sell_order_count}} / {{item.buy_order_count}}
                    | <span class="tooltip-label">Open Order Count:</span> {{item.open_sell_order_count}} / {{item.open_buy_order_count}}
                    | <span class="tooltip-label">Proportion:</span>
                    <color-text color_class="text-danger"
                                :content="item.sell_proportion"
                                :condition="content => content < 0.1"/>
                    | <span class="tooltip-label">Open Proportion:</span>
                    <color-text color_class="text-danger"
                                :content="item.trading_card_prices_proportion"
                                :condition="content => content < 0.1"/>
                    | <span class="tooltip-label">Available Time:</span>
                    <color-text color_class="text-primary"
                                :content="item.available_time ? new Date(item.available_time) : null"
                                :condition="content => content < new Date()"
                                :filter="content => content ? content.toLocaleTimeString() : null"/>
                </md-tooltip>
            </md-table-row>
        </md-table>
    </div>
</template>

<style scoped>
    .ppg-cell {
        width: 84px;
    }
    .ppg-cell >>> .md-table-cell-container {
        width: 84px;
    }

    .open-ppg-cell {
        width: 120px;
    }
    .open-ppg-cell >>> .md-table-cell-container {
        width: 120px;
    }

    .open-cov-cell {
        width: 120px;
    }
    .open-cov-cell >>> .md-table-cell-container  {
        width: 120px;
    }

    .open-obr-cell {
        width: 120px;
    }
    .open-obr-cell >>> .md-table-cell-container  {
        width: 120px;
    }

    .li-count-cell {
        width: 100px;
    }
    .li-count-cell >>> .md-table-cell-container {
        width: 100px;
    }

    .open-li-count-cell {
        width: 105px;
    }
    .open-li-count-cell >>> .md-table-cell-container {
        width: 105px;
    }

    .action-cell {
        width: 176px;
    }
    .action-cell >>> .md-table-cell-container {
        width: 176px;
        font-size: 0;
    }

    .account-filter {
        max-width: 180px;
    }
</style>

<script src="./booster_creators.js"></script>
