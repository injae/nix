export type CompactGuardPercent = number | null

declare module 'claude-code' {
  interface PluginState {
    'compact-guard': { percent: CompactGuardPercent; isSkipped: boolean }
  }
}
