<template>
    <div id="inventory">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="lowest_sell_order" md-sort-order="desc"
                  @md-selected="on_select">
            <md-table-toolbar class="md-elevation-2">
                <div class="md-toolbar-section-start">
                    <md-button class="md-raised md-primary"
                               @click="reload_assets"
                               :disabled="fetching">
                        {{fetching ? 'Pending' : 'Reload'}}
                    </md-button>
                </div>
                <md-field md-clearable class="md-toolbar-section-end">
                    <label for="marketable">Marketable</label>
                    <md-select v-model="filter.marketable" name="marketable" id="marketable">
                        <md-option :value="1">True</md-option>
                        <md-option :value="0">False</md-option>
                    </md-select>
                </md-field>
            </md-table-toolbar>
            <md-table-row slot="md-table-row" slot-scope="{ item }" :class="get_class(item)" md-selectable="single">
                <md-table-cell md-label="Id" class="name-cell">{{item.id}}</md-table-cell>
                <md-table-cell md-label="Name" class="name-cell">
                    <md-button class="md-dense" target="_blank" :href="item.listing_url">{{item.market_hash_name}}</md-button>
                </md-table-cell>
                <md-table-cell md-label="Goo Value" class="numeric-cell" md-sort-by="goo_value" md-numeric>
                    {{item.goo_value}}
                </md-table-cell>
                <md-table-cell md-label="Sell Price" class="numeric-cell" md-sort-by="lowest_sell_order" md-numeric>
                    <div class="md-list-item-text">
                        <span>{{item.lowest_sell_order}}</span>
                        <span>({{item.lowest_sell_order_exclude_vat}})</span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Sell Count" class="numeric-cell" md-sort-by="sell_order_count" md-numeric>
                    {{item.sell_order_count}}
                </md-table-cell>
                <md-table-cell md-label="Buy Price" class="numeric-cell" md-sort-by="highest_buy_order" md-numeric>
                    {{item.highest_buy_order}}
                </md-table-cell>
                <md-table-cell md-label="Buy Count" class="numeric-cell" md-sort-by="buy_order_count" md-numeric>
                    {{item.buy_order_count}}
                </md-table-cell>

                <md-tooltip md-direction="right">
                    {{item.assetid}} | {{item.type}}
                </md-tooltip>
            </md-table-row>
        </md-table>

        <md-snackbar :class="snackbar.type" md-position="left" :md-duration="Infinity" :md-active.sync="snackbar.active">
            <span>{{snackbar.message}}</span>
            <md-button class="md-primary" @click="snackbar.active = false">Close</md-button>
        </md-snackbar>
    </div>
</template>

<style scoped>
    .numeric-cell {
        width: 120px;
    }
    .numeric-cell >>> .md-table-cell-container {
        width: 120px;
    }

    .action-cell {
        width: 180px;
    }
    .action-cell >>> .md-table-cell-container {
        width: 180px;
    }

    .md-field {
        max-width: 120px;
    }
    .md-tooltip {
        transform: translate(48px, 32px);
    }
    .md-list-item-text :nth-child(2) {
        font-size: 12px;
        color: #9E9E9E;
    }
</style>

<script src="./inventory.js"></script>
