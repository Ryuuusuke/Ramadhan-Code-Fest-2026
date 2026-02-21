<template>
  <div class="wallet-box">
    <button v-if="!connected" @click="connect">
      Connect Phantom
    </button>

    <div v-else class="connected">
      <p>Connected Wallet</p>
      <code>{{ shortAddress }}</code>

      <button class="disconnect" @click="disconnect">
        Disconnect
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { getPhantomProvider } from '../../lib/solana'

const address = ref<string | null>(null)
const connected = computed(() => !!address.value)
const DISCONNECT_KEY = 'phantom_manual_disconnect'

const shortAddress = computed(() => {
  if (!address.value) return ''
  return address.value.slice(0, 4) + '...' + address.value.slice(-4)
})

const connect = async () => {
  const provider = getPhantomProvider()
  if (!provider) {
    alert('Phantom wallet not found')
    return
  }

  const res = await provider.connect()
  address.value = res.publicKey.toString()

  localStorage.removeItem(DISCONNECT_KEY)
}

const disconnect = async () => {
  const provider = getPhantomProvider()
  if (!provider) return

  await provider.disconnect()
  address.value = null

  localStorage.setItem(DISCONNECT_KEY, '1')
}

onMounted(async () => {
  await nextTick()

  setTimeout(async () => {
    if (localStorage.getItem(DISCONNECT_KEY)) return

    const provider = getPhantomProvider()
    if (!provider) return

    try {
      const res = await provider.connect({ onlyIfTrusted: true })
      address.value = res.publicKey.toString()
    } catch {}
  }, 300)
})
</script>

<style scoped>
.wallet-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

button {
  background: #7c3aed;
  color: white;
  border: none;
  padding: 12px 20px;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
}

.connected {
  background: #0f172a;
  color: white;
  padding: 16px 20px;
  border-radius: 12px;
  text-align: center;
}

.disconnect {
  background: #dc2626;
  margin-top: 10px;
}
</style>