<template>
    <div id="my-listings">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="price" md-sort-order="desc"
                  @md-selected="on_select">

            <md-table-toolbar class="md-elevation-2">
                <div class="md-toolbar-section-start">
                    <md-button class="md-raised md-primary"
                               @click="reload_all"
                               :disabled="fetching">
                        Reload
                    </md-button>
                </div>
            </md-table-toolbar>

            <md-table-toolbar slot="md-table-alternate-header" slot-scope="{ count }">
                <div class="md-toolbar-section-start">Selected: {{ count }}</div>
            </md-table-toolbar>

            <md-table-row slot="md-table-row" slot-scope="{ item }" md-selectable="multiple" md-auto-select>
                <md-table-cell md-label="Appid" class="numeric-cell" md-sort-by="market_fee_app" md-numeric>
                    {{item.market_fee_app}}
                </md-table-cell>
                <md-table-cell md-label="Name" class="name-cell">
                    {{item.market_name}}
                </md-table-cell>
                <md-table-cell md-label="Account" class="name-cell" md-sort-by="bot_name">
                    {{item.bot_name}}
                </md-table-cell>
                <md-table-cell md-label="Price" class="numeric-cell" md-sort-by="price" md-numeric>
                    <div class="md-list-item-text">
                        <span>{{item.price}}</span>
                        <span>({{item.price_exclude_vat}})</span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Lowest" class="numeric-cell" md-sort-by="lowest_sell_order" md-numeric>
                    <div class="md-list-item-text">
                        <span>{{item.lowest_sell_order }}</span>
                        <span>({{item.lowest_sell_order_exclude_vat}})</span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Date" class="numeric-cell" md-sort-by="listed_date">
                    {{item.listed_date}}
                </md-table-cell>
                <md-table-cell md-label="Confirming" class="numeric-cell" md-sort-by="confirming">
                    {{item.confirming}}
                </md-table-cell>

                <md-tooltip md-direction="right">
                    {{item.listingid}} | {{item.type}}
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
        margin-left: 12px;
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

<script src="./my_listings.js"></script>
