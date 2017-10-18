<template>
    <div id="booster-creators">
        <p>
            <span class="btn btn-primary"
                  @click="fetch_creatable"
                  :disabled="fetching">
                {{fetching ? 'fetching' : 'fetch'}}
            </span>
        </p>
        <table class="table">
            <tr>
                <th>appid</th>
                <th>name</th>
                <th>price</th>
                <th>foil avg</th>
                <th>ppg</th>
                <th>open ppg</th>
                <th>open cov</th>
                <th>open obr</th>
                <th>lc</th>
                <th>open lc</th>
                <th>order count</th>
                <th>proportion</th>
                <th>open order count</th>
                <th>open proportion</th>
                <th>atime</th>
                <th></th>
            </tr>
            <tr v-for="booster_creator in booster_creators">
                <td>{{booster_creator.appid}}</td>
                <td><span @click="$modal.show('booster-creator', { booster_creator })">{{booster_creator.name}}</span>
                </td>
                <td>{{booster_creator.price}}</td>
                <td>{{booster_creator.open_price.foil_average}}</td>
                <td>
                    <color-text color_class="text-primary"
                                :content="booster_creator.price_per_goo"
                                :condition="content => content > 0.57"/>
                </td>
                <td>
                    <color-text color_class="text-primary"
                                :content="booster_creator.open_price_per_goo"
                                :condition="content => content > base_ppg"/>
                </td>
                <td>
                    <color-text color_class="text-primary"
                                :content="booster_creator.open_price.coefficient_of_variation"
                                :condition="content => content < 0.15"/>
                </td>
                <td>
                    <color-text color_class="text-danger"
                                :content="booster_creator.open_price.over_baseline_rate"
                                :condition="content => content < 0.5"/>
                </td>
                <td>
                    <color-text color_class="text-primary"
                                :content="booster_creator.listing_booster_pack_count"
                                :condition="content => content === 0 && booster_creator.price_per_goo > 0.57"/>
                </td>
                <td>
                    <color-text color_class="text-danger"
                                :content="booster_creator.listing_trading_card_count"
                                :condition="content => content >= 5"/>
                </td>
                <td>{{booster_creator.sell_order_count}} / {{booster_creator.buy_order_count}}</td>
                <td>
                    <color-text color_class="text-danger"
                                :content="booster_creator.sell_proportion"
                                :condition="content => content < 0.1"/>
                </td>
                <td>{{booster_creator.open_sell_order_count}} / {{booster_creator.open_buy_order_count}}</td>
                <td>
                    <color-text color_class="text-danger"
                                :content="booster_creator.trading_card_prices_proportion"
                                :condition="content => content < 0.1"/>
                </td>
                <td>
                    <color-text color_class="text-primary"
                                :content="booster_creator.min_available_time ? new Date(booster_creator.min_available_time) : null"
                                :condition="content => content < new Date()"
                                :filter="content => content ? content.toLocaleTimeString() : null"/>
                </td>
                <td>
                    <span class="btn btn-primary" @click="create_and_sell(booster_creator)">sell</span>
                    <span class="btn btn-primary" @click="create_and_unpack(booster_creator)">unpack</span>
                    <span class="btn btn-primary" @click="sell_all_assets(booster_creator)">sell assets</span>
                </td>
            </tr>
        </table>
        <booster-creator-model />
    </div>
</template>

<script>
  import Notie from 'notie';
  import NProgress from 'nprogress';

  import ColorText from '../components/color_text.vue';
  import BoosterCreatorModel from './booster_creator_model.vue';

  function fetch_creatable() {
    if (this.fetching) {
      return;
    }

    this.fetching = true;
    NProgress.start();
    return fetch(`/booster_creators/creatable?base_ppg=${this.base_ppg}&limit=${this.limit}`)
        .then(response => response.json())
        .then(booster_creators => this.booster_creators = booster_creators)
        .then(() => {
          this.fetching = false;
          NProgress.done();
        })
        .catch(error => Notie.alert({
          type: 'error',
          text: error,
        }));
  }

  function create_and_sell(booster_creator) {
    return Notie.confirm({
      text: `confirm to create ${booster_creator.name}?`,
      submitCallback: () => fetch('/booster_creators/create_and_sell', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ appid: booster_creator.appid }),
      }).then(() => Notie.alert({
        type: 'success',
        text: 'success',
      })).catch(error => Notie.alert({
        type: 'error',
        text: error,
      }))
    });
  }

  function create_and_unpack(booster_creator) {
    return Notie.confirm({
      text: `confirm to create ${booster_creator.name}?`,
      submitCallback: () => fetch('/booster_creators/create_and_unpack', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ appid: booster_creator.appid }),
      }).then(() => Notie.alert({
        type: 'success',
        text: 'success',
      })).catch(error => Notie.alert({
        type: 'error',
        text: error,
      }))
    });
  }

  function sell_all_assets(booster_creator) {
    return Notie.confirm({
      text: `confirm to create ${booster_creator.name}?`,
      submitCallback: () => fetch('/booster_creators/sell_all_assets', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ appid: booster_creator.appid }),
      }).then(() => Notie.alert({
        type: 'success',
        text: 'success',
      })).catch(error => Notie.alert({
        type: 'error',
        text: error,
      }))
    });
  }

  function open_booster_creator_model(booster_creator) {
    this.$modal.show('booster-creator', { booster_creator });
  }

  export default {
    props: ['base_ppg', 'limit'],
    data: () => ({
      booster_creators: [],
      fetching: false,
    }),
    methods: {
      fetch_creatable,
      create_and_sell,
      create_and_unpack,
      sell_all_assets,
      open_booster_creator_model,
    },
    components: {
      ColorText,
      BoosterCreatorModel,
    }
  };
</script>

<style scoped>
    #booster-creators {
        padding: 2em 0;
    }
</style>
