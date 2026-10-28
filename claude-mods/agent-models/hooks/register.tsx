import type { AgentStatus, Register } from 'claude-code'

import { formatTail, shortModel } from './format'

// Agents still at work; finished ones drop off the line.
const LIVE: readonly AgentStatus[] = ['pending', 'running', 'waiting']

export const register: Register = on => {
  // agentId -> short model, recorded as each agent starts. Agents started
  // before the module (re)loaded are unknown and left off the line.
  // shortcut: module memory, reset on reload; $.state if that matters.
  const models = new Map<string, { label: string; model: string }>()

  on('agent.spawn', async ($, e, next) => {
    const result = await next(e)
    // Recording must never break the spawn itself.
    try {
      if (!('deny' in result) && result.agentId) {
        const label = e.workflow ? 'workflow' : e.subagentType
        models.set(result.agentId, { label, model: shortModel(result.model) })
      }
    } catch {
      // leave the agent off the line
    }
    return result
  })

  // The dim hint line under the prompt: keep the engine's line, with its live
  // "← N agents" pill, and add the running agents' models after it.
  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    if (models.size === 0) return next(e)
    const agents = await $.agent.list().catch(() => [])
    const live = agents.flatMap(a => {
      const known = models.get(a.id)
      return known && LIVE.includes(a.status) ? [known] : []
    })
    const tail = formatTail(live)
    return tail ? next({ ...e, props: { ...e.props, tail } }) : next(e)
  })
}
