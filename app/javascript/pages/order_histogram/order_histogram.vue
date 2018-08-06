<template>
    <div id="order_histogram">
        <md-card>
            <md-toolbar class="md-transparent" md-elevation="1">
                <h3 class="md-title">Order Graphs</h3>
            </md-toolbar>
            <md-content class="chart">
                <canvas ref="order_chart"></canvas>
            </md-content>
        </md-card>

        <md-card>
            <md-toolbar class="md-transparent" md-elevation="1">
                <h3 class="md-title">History</h3>
            </md-toolbar>
            <md-content class="chart">
                <canvas ref="history_chart"></canvas>
            </md-content>
        </md-card>
    </div>
</template>

<style scoped>
    .md-card:not(:first-child) {
        margin-top: 32px;
    }

    .chart {
        height: 300px;
        position: relative;
    }
</style>

<script src="./order_histogram.js"></script>
