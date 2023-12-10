<script setup lang="ts">
const contractAddress = ref('')
const data = ref({
  img: 'https://i.seadn.io/gae/CUhtaQy31ekplPzumVPNAmdjcMIDm6IB7ARw_Q4JOpu-dIXAvNPxTfItD4rJuFZI8x7BK8Z0-Ly2cmr182zXbpoN1uybC8h2l89csg?auto=format&dpr=1&w=384',
  title: 'Crypto Toys Club',
  id: '1016',
})
</script>

<template>
  <div mx-auto max-w-2xl>
    <h2 mb-10 text-3xl>
      NFT Bridge
    </h2>
    <UInput v-model="contractAddress" color="primary" variant="outline" placeholder="Search..." />
    <div v-if="data.img">
      <div mx-auto my-10 max-w-md>
        <img :src="data.img" mb-5>
        <div flex justify="between">
          <div>
            {{ data.title }}
          </div>
          <div>
            # {{ data.id }}
          </div>
        </div>
      </div>
      <UButton color="primary" variant="solid">
        Bridge to Fuji Chain
      </UButton>
    </div>
  </div>
</template>
