export type WorkUnit = { title: string; isSummarized: boolean }

declare module 'claude-code' {
  interface PluginState {
    'work-units': { units: WorkUnit[] }
  }
}
