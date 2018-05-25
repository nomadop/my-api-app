<template>
    <div id="inventory">
        <md-table v-model="inventory_assets" md-card md-fixed-header
                  md-sort="lowest_sell_order" md-sort-order="desc"
                  @md-selected="on_select">
            <md-table-row slot="md-table-row" slot-scope="{ item }" :class="get_class(item)" md-selectable="single">
                <md-table-cell md-label="Name" class="name-cell">{{item.market_hash_name}}</md-table-cell>
                <md-table-cell md-label="Goo Value" class="goo-value-cell" md-sort-by="goo_value" md-numeric>
                    {{item.goo_value}}
                </md-table-cell>
                <md-table-cell md-label="Sell Price" class="sell-price-cell" md-sort-by="lowest_sell_order" md-numeric>
                    {{item.lowest_sell_order}}
                </md-table-cell>
                <md-table-cell md-label="Sell Count" class="sell-count-cell" md-sort-by="sell_order_count" md-numeric>
                    {{item.sell_order_count}}
                </md-table-cell>
                <md-table-cell md-label="Actions" class="action-cell">
                    <md-button class="md-dense md-raised md-primary" :href="item.listing_url">Open Market</md-button>
                </md-table-cell>
            </md-table-row>
        </md-table>

        <md-snackbar :class="snackbar.type" md-position="left" :md-duration="Infinity" :md-active.sync="snackbar.active">
            <span>{{snackbar.message}}</span>
            <md-button class="md-primary" @click="snackbar.active = false">Close</md-button>
        </md-snackbar>
    </div>
</template>

<script src="./inventory.js"></script>
