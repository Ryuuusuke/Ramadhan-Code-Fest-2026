import { Connection, clusterApiUrl } from '@solana/web3.js'

export const connection = new Connection(clusterApiUrl('devnet'), 'confirmed')

export const getPhantomProvider = () => {
  if (typeof window === 'undefined') return null

  const anyWindow: any = window

  if (anyWindow?.phantom?.solana?.isPhantom) {
    return anyWindow.phantom.solana
  }

  if (anyWindow?.solana?.isPhantom) {
    return anyWindow.solana
  }

  return null
}