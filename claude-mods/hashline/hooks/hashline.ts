// Pure hashline logic: line splitting, patch grammar, application and the
// preview diff. No engine calls, so the tests exercise it directly.

export const MAX_FILE_BYTES = 4 * 1024 * 1024
export const MAX_OUTPUT_BYTES = 45_000

export type Line = { value: string; ending: string }
export type Operation = { start: number; end: number; body: string[] }

const encoder = new TextEncoder()
export const byteLength = (value: string) => encoder.encode(value).length

export function linesOf(value: string): Line[] {
  const lines: Line[] = []
  for (const row of value.matchAll(/([^\r\n]*)(\r\n|\n|\r|$)/g)) {
    if (row[0]) lines.push({ value: row[1]!, ending: row[2]! })
  }
  return lines
}

/**
 * Decodes strict UTF-8 with an optional BOM. Undefined for NUL bytes or
 * invalid UTF-8 (the decoder here has no `fatal` mode, so a lossless
 * re-encode is the check).
 */
export function decodeUtf8(bytes: Uint8Array): { value: string; bom: string } | undefined {
  if (bytes.includes(0)) return undefined
  const hasBom = bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf
  const body = hasBom ? bytes.subarray(3) : bytes
  const value = new TextDecoder('utf-8').decode(body)
  const again = encoder.encode(value)
  if (again.length !== body.length || again.some((byte, index) => byte !== body[index])) return undefined
  return { value, bom: hasBom ? '﻿' : '' }
}

function lineHash(number: number, value: string): string {
  let hash = 0x811c9dc5
  // Include the position so adjacent identical lines don't share a content-only anchor.
  const input = `${number}:${value}`
  for (let index = 0; index < input.length; index++) {
    hash = Math.imul(hash ^ input.charCodeAt(index), 0x01000193)
  }
  return ((hash ^ (hash >>> 16)) & 0xfff).toString(16).padStart(3, '0')
}

export function lineAnchor(number: number, value: string): string {
  return `${number}#${lineHash(number, value)}`
}

export function parsePatch(patch: string, lines: readonly Line[], seen: ReadonlySet<number>): Operation[] {
  const count = lines.length
  function checkAnchor(number: number, supplied: string) {
    if (lineHash(number, lines[number - 1]!.value) !== supplied.toLowerCase()) {
      throw new Error(`Hashline anchor mismatch at line ${number}. Re-read around that line and verify the intended edit.`)
    }
  }
  // Only a trailing newline is structural. Trailing whitespace on '+' rows is file content.
  const normalized = patch.replace(/\r\n/g, '\n')
  if (normalized.includes('\r') || normalized.includes('\0')) {
    throw new Error('Hashline patches cannot contain bare carriage returns or NUL bytes.')
  }
  const rows = normalized.replace(/\n$/, '').split('\n')
  const operations: Operation[] = []
  for (let index = 0; index < rows.length; index++) {
    const row = rows[index]!
    const range = /^(PUT|CUT) (\d+)#([\da-fA-F]{3})\.=(\d+)#([\da-fA-F]{3})(:)?$/.exec(row)
    const insertion = /^PUT ([<>])(\d+)#([\da-fA-F]{3}):$/.exec(row)
    const append = row === 'PUT >$:'
    const emptyHead = count === 0 && row === 'PUT <1:'
    if (!insertion && !append && !emptyHead && (!range || (range[1] === 'PUT') !== Boolean(range[6]))) {
      throw new Error(`Invalid hashline operation on patch row ${index + 1}. Copy each N#hash anchor from the read output.`)
    }
    const first = append ? count : emptyHead ? 1 : Number(insertion?.[2] ?? range?.[2])
    const last = range ? Number(range[4]) : first
    if (!emptyHead && (!Number.isSafeInteger(first) || first < 1 || last < first || last > count)) {
      throw new Error(`Anchor is outside the file on patch row ${index + 1}. Use PUT <1: for an empty file.`)
    }
    for (let line = first; !emptyHead && line <= last; line++) {
      if (!seen.has(line)) throw new Error(`Line ${line} has not been shown for this snapshot. Read it first.`)
    }
    if (range) {
      checkAnchor(first, range[3]!)
      checkAnchor(last, range[5]!)
    } else if (insertion) {
      checkAnchor(first, insertion[3]!)
    }
    const start = append || insertion?.[1] === '>' ? first : first - 1
    const body: string[] = []
    if (range?.[1] !== 'CUT') {
      while (rows[index + 1]?.startsWith('+')) body.push(rows[++index]!.slice(1))
      if (!body.length) throw new Error('PUT requires one or more + lines. Use CUT to delete.')
    }
    operations.push({ start, end: range ? last : start, body })
  }
  operations.sort((left, right) => left.start - right.start)
  for (let index = 1; index < operations.length; index++) {
    const previous = operations[index - 1]!
    const current = operations[index]!
    if (current.start < previous.end || current.start === previous.start) {
      throw new Error('Hashline operations overlap or share an insertion point. Combine them into one PUT.')
    }
  }
  return operations
}

export function applyPatch(lines: Line[], operations: Operation[]): string {
  const ending = lines.find(line => line.ending)?.ending ?? '\n'
  const lastEnding = lines.at(-1)?.ending ?? '\n'
  const output: Line[] = []
  let cursor = 0
  for (const operation of operations) {
    for (; cursor < operation.start; cursor++) output.push(lines[cursor]!)
    for (let index = 0; index < operation.body.length; index++) {
      const previous = operation.start + index < operation.end ? lines[operation.start + index] : undefined
      output.push({ value: operation.body[index]!, ending: previous?.ending || ending })
    }
    cursor = operation.end
  }
  for (; cursor < lines.length; cursor++) output.push(lines[cursor]!)
  return output
    .map((line, index) => line.value + (index === output.length - 1 ? lastEnding : line.ending || ending))
    .join('')
}

/** Unified diff of sorted, non-overlapping operations, built from the operations themselves. */
export function previewDiff(path: string, lines: Line[], operations: Operation[], context = 3): string {
  const groups: Operation[][] = []
  for (const operation of operations) {
    const group = groups.at(-1)
    if (group && operation.start - group.at(-1)!.end <= 2 * context) group.push(operation)
    else groups.push([operation])
  }
  const out = [`--- ${path}`, `+++ ${path}`]
  let delta = 0
  for (const group of groups) {
    const oldStart = Math.max(0, group[0]!.start - context)
    const oldEnd = Math.min(lines.length, group.at(-1)!.end + context)
    const rows: string[] = []
    let cursor = oldStart
    let added = 0
    let removed = 0
    for (const operation of group) {
      for (; cursor < operation.start; cursor++) rows.push(` ${lines[cursor]!.value}`)
      for (; cursor < operation.end; cursor++, removed++) rows.push(`-${lines[cursor]!.value}`)
      for (const value of operation.body) rows.push(`+${value}`), added++
    }
    for (; cursor < oldEnd; cursor++) rows.push(` ${lines[cursor]!.value}`)
    const oldCount = oldEnd - oldStart
    const newCount = oldCount - removed + added
    out.push(`@@ -${oldStart + 1},${oldCount} +${oldStart + 1 + delta},${newCount} @@`, ...rows)
    delta += added - removed
  }
  return out.join('\n')
}

/** Cuts text to at most `maxBytes` UTF-8 bytes at a line boundary. */
export function capBytes(value: string, maxBytes: number): { text: string; truncated: boolean } {
  if (byteLength(value) <= maxBytes) return { text: value, truncated: false }
  const kept: string[] = []
  let used = 0
  for (const row of value.split('\n')) {
    const size = byteLength(row) + 1
    if (used + size > maxBytes) break
    kept.push(row)
    used += size
  }
  return { text: kept.join('\n'), truncated: true }
}
