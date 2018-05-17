<template>
    <md-table v-model="booster_creators" md-card>
        <md-table-toolbar>
            <p>
                <md-button class="md-raised md-primary"
                           @click="fetch_creatable"
                           :disabled="fetching">
                    {{fetching ? 'fetching' : 'fetch'}}
                </md-button>
            </p>
        </md-table-toolbar>
        <md-table-row slot="md-table-row" slot-scope="{ item }">
            <md-table-cell md-label="appid">{{item.appid}}</md-table-cell>
            <md-table-cell md-label="name">{{item.name}}</md-table-cell>
            <md-table-cell md-label="price">{{item.price}}</md-table-cell>
            <md-table-cell md-label="foil avg">{{item.open_price.foil_average}}</md-table-cell>
            <md-table-cell md-label="ppg">
                <color-text color_class="text-primary"
                            :content="item.price_per_goo"
                            :condition="content => content > 0.57"/>
            </md-table-cell>
            <md-table-cell md-label="open ppg">
                <color-text color_class="text-primary"
                            :content="item.open_price_per_goo"
                            :condition="content => content > base_ppg"/>
            </md-table-cell>
            <md-table-cell md-label="open cov">
                <color-text color_class="text-primary"
                            :content="item.open_price.coefficient_of_variation"
                            :condition="content => content < 0.15"/>
            </md-table-cell>
            <md-table-cell md-label="open obr">
                <color-text color_class="text-danger"
                            :content="item.open_price.over_baseline_rate"
                            :condition="content => content < 0.5"/>
            </md-table-cell>
            <md-table-cell md-label="lc/ic">
                <color-text color_class="text-primary"
                            :content="item.listing_booster_pack_count"
                            :condition="content => content === 0 && item.price_per_goo > 0.57"/>
                /
                <color-text color_class="text-danger"
                            :content="item.inventory_assets_count"
                            :condition="content => content >= 1"/>
            </md-table-cell>
            <md-table-cell md-label="open lc/ic">
                <color-text color_class="text-danger"
                            :content="item.listing_trading_card_count"
                            :condition="content => content >= 5"/>
                /
                <color-text color_class="text-danger"
                            :content="item.inventory_cards_count"
                            :condition="content => content >= 3"/>
            </md-table-cell>
            <md-table-cell md-label="order count">{{item.sell_order_count}} / {{item.buy_order_count}}</md-table-cell>
            <md-table-cell md-label="proportion">
                <color-text color_class="text-danger"
                            :content="item.sell_proportion"
                            :condition="content => content < 0.1"/>
            </md-table-cell>
            <md-table-cell md-label="open order count">{{item.open_sell_order_count}} / {{item.open_buy_order_count}}
            </md-table-cell>
            <md-table-cell md-label="open proportion">
                <color-text color_class="text-danger"
                            :content="item.trading_card_prices_proportion"
                            :condition="content => content < 0.1"/>
            </md-table-cell>
            <md-table-cell md-label="atime">
                <color-text color_class="text-primary"
                            :content="item.min_available_time ? new Date(item.min_available_time) : null"
                            :condition="content => content < new Date()"
                            :filter="content => content ? content.toLocaleTimeString() : null"/>
            </md-table-cell>
            <md-table-cell md-label="actions">
                <md-button class="md-dense md-raised md-primary" @click="create_and_sell(item)">sell</md-button>
                <md-button class="md-dense md-raised md-primary" @click="create_and_unpack(item)">unpack</md-button>
                <md-button class="md-dense md-raised md-primary" @click="sell_all_assets(item)">sell assets</md-button>
            </md-table-cell>
        </md-table-row>
    </md-table>
</template>

<script src="./booster_creators.js"></script>
