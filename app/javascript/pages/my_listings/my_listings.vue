<template>
    <div id="my-listings">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="price" md-sort-order="desc"
                  @md-selected="on_select">

            <md-table-toolbar class="md-elevation-2">
                <div class="md-toolbar-section-start">
                    <md-button class="md-raised md-primary"
                               @click="fetch_all"
                               :disabled="fetching">
                        Load
                    </md-button>
                    <md-button class="md-raised md-primary"
                               @click="reload_all"
                               :disabled="fetching">
                        Reload
                    </md-button>
                </div>

                <div class="md-toolbar-section-end">
                    <md-field class="account-selector" md-clearable>
                        <label>Account</label>
                        <md-select v-model="filter.account">
                            <md-option v-for="account in accounts" :value="account.bot_name">{{account.bot_name}}</md-option>
                        </md-select>
                    </md-field>

                    <md-switch v-model="filter.confirming">Confirming</md-switch>
                </div>
            </md-table-toolbar>

            <md-table-toolbar slot="md-table-alternate-header" slot-scope="{ count }">
                <div class="md-toolbar-section-start">Selected: {{ count }}</div>

                <div class="md-toolbar-section-end">
                    <md-button class="md-raised md-primary" @click="cancel_selected"
                               :disabled="fetching || selected.length === 0">
                        Cancel
                    </md-button>
                </div>
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
                <md-table-cell md-label="BC COST" class="numeric-cell" md-sort-by="booster_creator_cost" md-numeric>
                    {{item.booster_creator_cost}}
                </md-table-cell>
                <md-table-cell md-label="Date" class="numeric-cell" md-sort-by="listed_date">
                    {{item.listed_date}}
                </md-table-cell>

                <md-tooltip md-direction="right">
                    {{item.listingid}} | {{item.type}}
                </md-tooltip>
            </md-table-row>
        </md-table>
    </div>
</template>

<style scoped>
    .action-cell {
        width: 180px;
    }
    .action-cell >>> .md-table-cell-container {
        width: 180px;
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
