<template>
    <span id="color-text" :class="classObject">{{displayText}}</span>
</template>

<script>
  export default {
    props: ['color_class', 'content', 'condition', 'filter'],
    computed: {
      classObject () {
        return { [this.color_class]: this.condition(this.content) };
      },
      displayText () {
        return this.filter ? this.filter(this.content) : this.content;
      }
    }
  }
</script>

<style scoped>
    .text-primary {
        color: #448AFF;
    }

    .text-danger {
        color: #FF5252;
    }
</style>