<template>
 <td id="color-text" :class="classObject">{{content}}</td>
</template>

<script>
 export default {
   props: ['color_class', 'content', 'condition'],
   computed: {
     classObject: function () {
       return { [this.color_class]: this.condition(this.content) };
     }
   }
 }
</script>