export type WorkUnitsCheckpoint = { cwd: string }

export type WorkUnit = { title: string; isSummarized: boolean }

declare module 'claude-code' {
  interface PluginState {
    'work-units': { checkpoint: WorkUnitsCheckpoint; units: WorkUnit[] }
  }
}
