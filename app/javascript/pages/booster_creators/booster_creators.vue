<template>
    <div id="booster-creators">
        <md-table v-model="booster_creators" md-card md-fixed-header
                  md-sort="open_price_per_goo" md-sort-order="desc"
                  @md-selected="on_select">
            <md-table-toolbar class="md-elevation-2">
                <md-button class="md-raised md-primary"
                           @click="fetch_creatable"
                           :disabled="fetching">
                    {{fetching ? 'fetching' : 'fetch'}}
                </md-button>
            </md-table-toolbar>
            <md-table-row slot="md-table-row" slot-scope="{ item }" :class="get_class(item)" md-selectable="single">
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
                <md-table-cell md-label="Open COV" class="open-cov-cell" md-numeric>
                    <color-text color_class="text-primary"
                                :content="item.open_price.coefficient_of_variation"
                                :condition="content => content < 0.5"/>
                </md-table-cell>
                <md-table-cell md-label="L/I Count" class="li-count-cell">
                    <color-text color_class="text-primary"
                                :content="item.listing_booster_pack_count"
                                :condition="content => content === 0 && item.price_per_goo > 0.57"/>
                    /
                    <color-text color_class="text-danger"
                                :content="item.inventory_assets_count"
                                :condition="content => content >= 1"/>
                </md-table-cell>
                <md-table-cell md-label="Open L/I Count" class="open-li-count-cell">
                    <color-text color_class="text-danger"
                                :content="item.listing_trading_card_count"
                                :condition="content => content >= 5"/>
                    /
                    <color-text color_class="text-danger"
                                :content="item.inventory_cards_count"
                                :condition="content => content >= 3"/>
                </md-table-cell>
                <md-table-cell md-label="Actions" class="action-cell">
                    <md-button class="md-dense md-raised md-primary" @click="create_and_sell(item)">sell</md-button>
                    <md-button class="md-dense md-raised md-primary" @click="create_and_unpack(item)">unpack</md-button>
                    <md-button class="md-dense md-raised md-primary" @click="sell_all_assets(item)">sell assets</md-button>
                </md-table-cell>
                <md-tooltip md-direction="bottom">
                    <span class="tooltip-label">Appid:</span> {{item.appid}}
                    | <span class="tooltip-label">Price:</span> {{item.price}}
                    | <span class="tooltip-label">AVG Foil Price:</span> {{item.open_price.foil_average}}
                    | <span class="tooltip-label">Open OBR:</span>
                    <color-text color_class="text-danger"
                                :content="item.open_price.over_baseline_rate"
                                :condition="content => content < 0.5"/>
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
                                :content="item.min_available_time ? new Date(item.min_available_time) : null"
                                :condition="content => content < new Date()"
                                :filter="content => content ? content.toLocaleTimeString() : null"/>
                </md-tooltip>
            </md-table-row>
        </md-table>

        <md-dialog-confirm :md-active.sync="confirm.active"
                           :md-title="confirm.title"
                           @md-confirm="confirm.callback"
                           md-confirm-text="Yes"
                           md-cancel-text="No"
        />

        <md-snackbar :class="snackbar.type" md-position="left" :md-duration="Infinity" :md-active.sync="snackbar.active">
            <span>{{snackbar.message}}</span>
            <md-button class="md-primary" @click="snackbar.active = false">Close</md-button>
        </md-snackbar>
    </div>
</template>

<style scoped>
    .ppg-cell >>> .md-table-cell-container {
        width: 84px;
    }

    .open-ppg-cell >>> .md-table-cell-container {
        width: 120px;
    }

    .open-cov-cell >>> .md-table-cell-container  {
        width: 120px;
    }

    .li-count-cell >>> .md-table-cell-container {
        width: 120px;
    }

    .open-li-count-cell >>> .md-table-cell-container {
        width: 150px;
    }

    .action-cell >>> .md-table-cell-container {
        width: 365px;
    }
</style>

<script src="./booster_creators.js"></script>
