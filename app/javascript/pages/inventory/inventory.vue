<template>
    <div id="inventory">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="lowest_sell_order" md-sort-order="desc"
                  @md-selected="on_select">

            <md-table-toolbar class="md-elevation-2">
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
                    <md-field md-clearable>
                        <label>Sell PPG</label>
                        <md-input v-model="filter.sell_ppg"></md-input>
                    </md-field>

                    <md-field md-clearable>
                        <label>Marketable</label>
                        <md-select v-model="filter.marketable">
                            <md-option :value="1">True</md-option>
                            <md-option :value="0">False</md-option>
                        </md-select>
                    </md-field>
                </div>
            </md-table-toolbar>

            <md-table-toolbar slot="md-table-alternate-header" slot-scope="{ count }">
                <div class="md-toolbar-section-start">Selected: {{ count }}</div>

                <div class="md-toolbar-section-end">
                    <md-field>
                        <label>Sell PPG</label>
                        <md-input v-model="sell_ppg"></md-input>
                    </md-field>
                    <md-button class="md-raised md-primary" @click="sell_by_ppg"
                               :disabled="fetching || selected.length === 0">
                        Sell By PPG
                    </md-button>
                </div>
            </md-table-toolbar>

            <md-table-row slot="md-table-row" slot-scope="{ item }"
                          :md-disabled="item.marketable === 0" md-selectable="multiple">
                <md-table-cell md-label="Name" class="name-cell">
                    {{item.market_hash_name}}
                </md-table-cell>
                <md-table-cell md-label="Goo Value" class="numeric-cell" md-sort-by="goo_value" md-numeric>
                    {{item.goo_value}}
                </md-table-cell>
                <md-table-cell md-label="Sell Price" class="numeric-cell" md-sort-by="lowest_sell_order" md-numeric>
                    {{item.lowest_sell_order_exclude_vat}}
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

                <md-tooltip md-direction="right">
                    {{item.assetid}} | {{item.type}}
                </md-tooltip>
            </md-table-row>
        </md-table>
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
