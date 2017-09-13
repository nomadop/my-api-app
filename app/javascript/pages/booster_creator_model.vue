<template>
    <modal name="booster-creator" @before-open="before_open">
        name: {{booster_creator.name}}
    </modal>
</template>

<script>
  import Notie from 'notie';
  import NProgress from 'nprogress';

  export default {
    data: () => ({
      booster_creator: {},
    }),
    methods: {
      before_open (event) {
        this.booster_creator = event.params.booster_creator;
      }
    },
  };
</script>

<style scoped>
</style>
