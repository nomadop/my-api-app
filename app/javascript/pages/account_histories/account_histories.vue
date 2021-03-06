<template>
    <div id="account-histories">
        <md-table v-model="items" md-card md-fixed-header
                  md-sort="date" md-sort-order="asc">

            <md-table-toolbar class="md-elevation-2">
                <md-badge class="md-primary" :md-content="items.length" />
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
                    <md-datepicker class="date-selector" v-model="from_date" md-immediately />
                    <md-switch v-model="include_market">Market</md-switch>
                </div>

                <div class="md-toolbar-section-end">
                    <md-field md-clearable>
                        <label>Type</label>
                        <md-select v-model="filter.type">
                            <md-option value="购买">购买</md-option>
                            <md-option value="退款">退款</md-option>
                            <md-option value="礼物购买">礼物购买</md-option>
                        </md-select>
                    </md-field>

                    <md-field md-clearable>
                        <label>Payment</label>
                        <md-select v-model="filter.payment">
                            <md-option value="钱包">钱包</md-option>
                            <md-option value="支付宝">支付宝</md-option>
                            <md-option value="微信">微信</md-option>
                            <md-option value="Visa">Visa</md-option>
                            <md-option value="万事达">万事达</md-option>
                            <md-option value="零售">零售</md-option>
                            <md-option value="贝宝">贝宝</md-option>
                        </md-select>
                    </md-field>

                    <md-field class="account-selector" md-clearable>
                        <label>Account</label>
                        <md-select v-model="filter.account">
                            <md-option v-for="account in accounts" :value="account.bot_name">{{account.bot_name}}</md-option>
                        </md-select>
                    </md-field>
                </div>
            </md-table-toolbar>

            <md-table-row slot="md-table-row" slot-scope="{ item }">
                <md-table-cell md-label="Account" class="date-cell" md-sort-by="account.bot_name">
                    {{item.account.bot_name}}
                </md-table-cell>
                <md-table-cell md-label="Date" class="date-cell" md-sort-by="date">
                    {{item.formatted_date}}
                </md-table-cell>
                <md-table-cell md-label="Items" class="item-cell">
                    <md-chip v-for="chip in item.items" :class="{refunded: item.refunded}">{{chip}}</md-chip>
                </md-table-cell>
                <md-table-cell md-label="Type" class="type-cell" md-sort-by="type">
                    <div class="md-list-item-text">
                        <span>{{item.type }}</span>
                        <span>{{item.payment}}</span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Total" class="numeric-cell" md-sort-by="total" md-numeric>
                    <div class="md-list-item-text">
                        <span>{{item.total_text}}</span>
                        <span v-if="item.refunded">Refunded</span>
                    </div>
                </md-table-cell>
                <md-table-cell md-label="Change" class="numeric-cell" md-sort-by="change" md-numeric>
                    <div class="md-list-item-text">
                        <span>{{item.change_text}}</span>
                        <span>{{item.balance_text}}</span>
                    </div>
                </md-table-cell>
            </md-table-row>
        </md-table>

        <md-card class="chart-card">
            <md-toolbar class="md-transparent" md-elevation="1">
                <h3 class="md-title">Market Chart</h3>
            </md-toolbar>
            <md-content class="market-chart">
                <canvas ref="canvas"></canvas>
            </md-content>
        </md-card>
    </div>
</template>

<style scoped>
    .chart-card {
        margin-top: 32px;
    }

    .market-chart {
        height: 400px;
        position: relative;
    }

    .date-cell {
        width: 84px;
    }
    .date-cell >>> .md-table-cell-container {
        width: 84px;
    }

    .type-cell {
        width: 150px;
    }
    .type-cell >>> .md-table-cell-container {
        width: 150px;
    }

    .md-tooltip {
        transform: translate(48px, 32px);
    }
    .md-list-item-text :nth-child(2) {
        font-size: 12px;
        color: #9E9E9E;
    }

    .item-cell >>> .md-table-cell-container {
        padding-bottom: 2px;
    }
    .md-chip {
        margin-bottom: 4px;
    }
    .refunded {
        color: #A9A9A9;
        text-decoration: line-through;
    }
</style>

<script src="./account_histories.js"></script>
