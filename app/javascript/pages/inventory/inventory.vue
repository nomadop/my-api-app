<template>
    <div id="inventory">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="lowest_sell_order" md-sort-order="desc"
                  @md-selected="on_select">

            <md-table-toolbar class="md-elevation-2">
                <md-badge class="md-primary" :md-content="items.length" />
                <div class="md-toolbar-section-start">
                    <md-button class="md-raised md-primary"
                               @click="fetch_assets"
                               :disabled="fetching">
                        Load
                    </md-button>
                    <md-button class="md-raised md-primary"
                               @click="reload_assets"
                               :disabled="fetching">
                        Reload
                    </md-button>
                </div>

                <div class="md-toolbar-section-end">
                    <md-switch v-model="filter.marketable">Marketable</md-switch>

                    <md-field md-clearable>
                        <label>Sell PPG</label>
                        <md-input v-model="filter.sell_ppg"></md-input>
                    </md-field>

                    <md-field class="account-selector" md-clearable>
                        <label>Account</label>
                        <md-select v-model="filter.account">
                            <md-option v-for="account in accounts" :value="account.bot_name">{{account.bot_name}}</md-option>
                        </md-select>
                    </md-field>
                </div>
            </md-table-toolbar>

            <md-table-toolbar slot="md-table-alternate-header" slot-scope="{ count }">
                <div class="md-toolbar-section-start">Selected: {{ count }}</div>

                <div class="md-toolbar-section-end">
                    <md-button class="md-raised md-primary" @click="grind_into_goo"
                               :disabled="fetching || selected.length === 0">
                        Grind
                    </md-button>
                    <md-field>
                        <label>Sell PPG</label>
                        <md-input v-model="sell_ppg"></md-input>
                    </md-field>
                    <md-button class="md-raised md-primary" @click="sell_by_ppg"
                               :disabled="fetching || selected.length === 0">
                        Sell
                    </md-button>
                    <md-field class="account-selector">
                        <label>Account</label>
                        <md-select v-model="selected_account">
                            <md-option v-for="account in accounts" :value="account.id">{{account.bot_name}}</md-option>
                        </md-select>
                    </md-field>
                    <md-button class="md-raised md-primary" @click="send_trade_offer"
                               :disabled="fetching || selected.length === 0 || selected_account === ''">
                        Trade
                    </md-button>
                </div>
            </md-table-toolbar>

            <md-table-row slot="md-table-row" slot-scope="{ item }" md-selectable="multiple">
                <md-table-cell md-label="Name" class="name-cell">
                    <div class="md-list-item-text">
                        <span>{{item.market_hash_name}}</span>
                        <span>id: {{item.id}} | Asset id: {{item.assetid}}</span>
                        <p>{{item.type}}</p>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Account" class="account-cell" md-sort-by="bot_name">
                    {{item.bot_name}}
                </md-table-cell>
                <md-table-cell md-label="Sell Price" class="numeric-cell" md-sort-by="lowest_sell_order" md-numeric>
                    <div class="md-list-item-text">
                        <span>{{item.lowest_sell_order_exclude_vat}}</span>
                        <span>({{item.goo_value}})</span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Sell PPG" class="numeric-cell" md-sort-by="price_per_goo_exclude_vat" md-numeric>
                    {{item.price_per_goo_exclude_vat | round }}
                </md-table-cell>
                <md-table-cell md-label="Sell Count" class="numeric-cell" md-sort-by="sell_order_count" md-numeric>
                    {{item.sell_order_count}}
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

<style scoped>
    .action-cell {
        width: 100px;
    }
    .action-cell >>> .md-table-cell-container {
        width: 100px;
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
