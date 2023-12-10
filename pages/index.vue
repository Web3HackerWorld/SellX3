<script setup lang="ts">
import { polygonMumbai } from 'viem/chains'
import { createPublicClient, createWalletClient, custom, decodeAbiParameters, formatEther, http, keccak256, parseAbiItem, publicActions, toHex } from 'viem'
import MockNFT from '@/contracts/abis/MockNFT.json'

const contractAddress = $ref('0x70C8552868a7a10c62470456E1f1a48189307b74')
const tokenId = $ref('3042')
let data = $ref({

})
let name = $ref('')

async function getClient(chain) {
  const [account] = await window.ethereum.request({ method: 'eth_requestAccounts' })
  const walletClient = createWalletClient({
    account,
    chain,
    transport: custom(window.ethereum),
  }).extend(publicActions)

  try {
    await walletClient.switchChain({ id: chain.id })
  }
  catch (e) {
    if (e.code === 4902) {
      await walletClient.addChain({ chain })
      await walletClient.switchChain({ id: chain.id })
    }
  }

  return walletClient
}

let client = $ref('')
onMounted(async () => {
  client = await getClient(polygonMumbai)
})

let isLoading = $ref(false)
async function getNFTData() {
  if (!contractAddress || !tokenId || isLoading)
    return

  isLoading = true

  const params = {
    address: contractAddress,
    abi: MockNFT,
    functionName: 'tokenURI',
    args: [tokenId],
  }

  name = await client.readContract({
    ...params,
    functionName: 'name',
    args: [],
  })
  const url = await client.readContract(params)
  data = await $fetch(url)
  if (data.image.startsWith('ipfs://'))
    data.image = data.image.replace('ipfs://', 'https://ipfs.io/ipfs/')

  isLoading = false
}

async function doBridge () {
  console.log(`====> doBridge`)
}
</script>

<template>
  <div mx-auto max-w-2xl>
    <h2 mb-10 text-3xl>
      NFT Bridge
    </h2>
    <div space-y-5>
      <UFormGroup label="contractAddress" name="contractAddress">
        <UInput v-model="contractAddress" />
      </UFormGroup>

      <UFormGroup label="tokenId" name="tokenId">
        <UInput v-model="tokenId" />
      </UFormGroup>

      <UButton :loading="isLoading" color="white" variant="solid" @click="getNFTData">
        Query NFT Data
      </UButton>
    </div>
    <div v-if="data.image">
      <div mx-auto my-10 max-w-md>
        <img :src="data.image" mb-5>
        <div flex justify="between">
          <div>
            {{ name }}
          </div>
          <div>
            # {{ tokenId }}
          </div>
        </div>
      </div>
      <UButton :loading="isLoading" @click="doBridge">
        Bridge NFT to Fuji
      </UButton>
    </div>
  </div>
</template>
