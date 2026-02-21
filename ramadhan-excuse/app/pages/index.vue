<template>
  <main class="container">
    <h1>Ramadhan Excuse Protocol</h1>
    <p>Generate alasan absah kenapa kamu skip ibadah hari ini 😈</p>

    <ClientOnly>
      <WalletConnect />
    </ClientOnly>
  </main>
</template>

<script setup lang="ts">
import WalletConnect from '~/components/WalletConnect.vue'
</script>

<style scoped>
.container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 20px;
  background: radial-gradient(circle at top, #1f2933, #020617);
  color: white;
  text-align: center;
}

h1 {
  font-size: 2.2rem;
}

p {
  opacity: 0.7;
  max-width: 420px;
}
</style>