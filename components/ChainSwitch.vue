<script setup lang="ts">
import { avalancheFuji, polygonMumbai } from 'viem/chains'

const items = [
  polygonMumbai.network,
  avalancheFuji.network,
]

const selected = ref(items[0])
</script>

<template>
  <USelectMenu v-model="selected" :options="items" />
</template>
