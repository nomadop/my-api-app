<template>
    <md-card>
        <md-toolbar class="md-transparent" md-elevation="0">
            <h3 class="md-title">Order Graphs</h3>
        </md-toolbar>
        <md-content class="order-chart">
            <canvas ref="canvas"></canvas>
        </md-content>
    </md-card>
</template>

<style scoped>
    .order-chart {
        height: 300px;
        position: relative;
    }
</style>

<script src="./order_histogram.js"></script>
