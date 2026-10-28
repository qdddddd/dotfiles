// Pure formatting for the hint tail, kept apart from the hooks so tests can
// call it directly.

export type LiveAgent = { label: string; model: string }

/**
 * The model as a short name: "claude-opus-5-5[1m]" -> "opus-5.5",
 * "claude-haiku-4-5-20251001" -> "haiku-4.5"; an alias ("haiku") stays.
 */
export function shortModel(model: string): string {
  let m = model.trim().replace(/\[[^\]]*\]$/, '')
  if (m.startsWith('claude-')) {
    m = m
      .slice('claude-'.length)
      .replace(/-\d{8}$/, '')
      .replace(/-(\d+)-(\d+)$/, '-$1.$2')
  }
  return m.toLowerCase()
}

/**
 * One group per label and model, in first-seen order, counted when repeated:
 * "Explore haiku-4.5 · 3× workflow opus-5.5". Empty when nothing runs.
 */
export function formatTail(agents: readonly LiveAgent[]): string {
  const groups = new Map<string, number>()
  for (const a of agents) {
    const key = `${a.label} ${a.model}`
    groups.set(key, (groups.get(key) ?? 0) + 1)
  }
  return [...groups].map(([key, n]) => (n > 1 ? `${n}× ${key}` : key)).join(' · ')
}
