import type { EngineInterface, Register } from 'claude-code'

import {
  MAX_FILE_BYTES,
  MAX_OUTPUT_BYTES,
  applyPatch,
  byteLength,
  capBytes,
  decodeUtf8,
  lineAnchor,
  linesOf,
  parsePatch,
  previewDiff,
  type Line,
} from './hashline'

const READ = 'mcp__hashline__hashline_read'
const EDIT = 'mcp__hashline__hashline_edit'

const READ_DESCRIPTION =
  'Read a local UTF-8 text file as `N#hash:text` lines under a `[path#TAG]` snapshot header, ' +
  `for ${EDIT}. Only lines shown by this tool for the current snapshot can be edited. ` +
  'offset is 1-based (default 1); limit defaults to 250 lines (max 2000).'

const EDIT_DESCRIPTION =
  `Edit an existing file using the 16-hex snapshot tag and N#hash anchors from ${READ}. ` +
  'Copy the anchors exactly. If the read shows `2#abc:old`, replace that line with `PUT 2#abc.=2#abc:\\n+new`. ' +
  'Use `PUT N#hash.=M#hash:` to replace an inclusive range, `CUT N#hash.=M#hash` to delete one, ' +
  'and `PUT <N#hash:` or `PUT >N#hash:` to insert before or after a line. ' +
  '`PUT >$:` appends after the last displayed line only if it is the end of the file; `PUT <1:` inserts into an empty file. ' +
  'Prefix PUT body lines with + (a bare + is a blank line). Do not include read prefixes in the body. ' +
  'All anchors refer to the original snapshot. Set preview=true for a dry-run diff. A subsequent edit requires a fresh read.'

type Snapshot = { hash: string; lines: Line[]; value: string; bom: string }
type Seen = { hash: string; lines: Set<number> }

function fromBase64(base64: string): Uint8Array {
  const binary = atob(base64)
  const bytes = new Uint8Array(binary.length)
  for (let index = 0; index < binary.length; index++) bytes[index] = binary.charCodeAt(index)
  return bytes
}

async function sha256(bytes: Uint8Array): Promise<string> {
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes))
  return Array.from(digest, byte => byte.toString(16).padStart(2, '0')).join('')
}

async function resolvePath($: EngineInterface, path: string): Promise<string> {
  if (typeof path !== 'string' || !path || path.includes('\0')) throw new Error('Supply a valid file path.')
  let spelled = path
  if (path === '~' || path.startsWith('~/')) {
    const home = await $.env.get('HOME')
    if (!home) throw new Error('Cannot expand ~ without HOME. Use an absolute path.')
    spelled = home + path.slice(1)
  }
  const stat = await $.fs.stat(spelled, { resolve: true })
  if (!stat.realPath) throw new Error('Cannot resolve the file path.')
  if (stat.kind !== 'file' || stat.size > MAX_FILE_BYTES) {
    throw new Error('Hashline requires a regular UTF-8 file of up to 4 MiB.')
  }
  return stat.realPath
}

async function snapshot($: EngineInterface, path: string): Promise<Snapshot> {
  const { base64 } = await $.fs.read(path, { as: 'bytes' })
  const bytes = fromBase64(base64)
  const decoded = bytes.length <= MAX_FILE_BYTES ? decodeUtf8(bytes) : undefined
  if (!decoded) throw new Error('Hashline requires a UTF-8 text file of up to 4 MiB.')
  return { hash: await sha256(bytes), lines: linesOf(decoded.value), value: decoded.bom + decoded.value, bom: decoded.bom }
}

const message = (error: unknown) => (error instanceof Error ? error.message : String(error))

export const register: Register = on => {
  // realPath -> snapshot hash and the line numbers shown for it.
  // shortcut: module memory, reset when the mod reloads (edits then ask for a re-read); $.state if that matters.
  const seen = new Map<string, Seen>()
  // realPath -> tail of that file's edit queue, so edits to one file run one at a time.
  const queues = new Map<string, Promise<unknown>>()

  function serial<T>(key: string, task: () => Promise<T>): Promise<T> {
    const run = (queues.get(key) ?? Promise.resolve()).catch(() => undefined).then(task)
    const tail = run.catch(() => undefined)
    queues.set(key, tail)
    void tail.then(() => queues.get(key) === tail && queues.delete(key))
    return run
  }

  on('session.start', async ($, e, next) => {
    await $.tool.register({
      name: 'hashline_read',
      description: READ_DESCRIPTION,
      isDeferred: false,
      inputSchema: {
        type: 'object',
        properties: {
          path: { type: 'string', description: 'File path, absolute or relative to the working directory' },
          offset: { type: 'integer', minimum: 1 },
          limit: { type: 'integer', minimum: 1, maximum: 2000 },
        },
        required: ['path'],
        additionalProperties: false,
      },
    })
    await $.tool.register({
      name: 'hashline_edit',
      description: EDIT_DESCRIPTION,
      isDeferred: false,
      inputSchema: {
        type: 'object',
        properties: {
          path: { type: 'string' },
          tag: { type: 'string', pattern: '^[0-9a-fA-F]{16}$' },
          patch: { type: 'string', minLength: 1, maxLength: 250_000 },
          preview: { type: 'boolean' },
        },
        required: ['path', 'tag', 'patch'],
        additionalProperties: false,
      },
    })
    return next(e)
  })

  on('session.end', ($, e, next) => {
    seen.clear()
    return next(e)
  })

  on('tool.run', { tool: READ }, async ($, e) => {
    try {
      const input = e as unknown as { path: string; offset?: number; limit?: number }
      const path = await resolvePath($, input.path)
      const { hash, lines } = await snapshot($, path)
      const previous = seen.get(path)
      const anchors = previous?.hash === hash ? previous.lines : new Set<number>()
      const tag = hash.slice(0, 16)
      const rows = [`[${input.path}#${tag}]`]
      const offset = input.offset ?? 1
      if (offset > Math.max(1, lines.length)) throw new Error(`Offset ${offset} exceeds ${lines.length} lines.`)
      let displayed = 0
      let index = offset - 1
      for (; index < Math.min(lines.length, offset - 1 + (input.limit ?? 250)); index++) {
        const { value } = lines[index]!
        const row = `${lineAnchor(index + 1, value)}:${value}`
        const size = byteLength(row) + 1
        if (size > MAX_OUTPUT_BYTES) {
          rows.push(`[Line ${index + 1} exceeds the output limit and cannot be used as an anchor]`)
          continue
        }
        if (displayed + size > MAX_OUTPUT_BYTES) break
        displayed += size
        rows.push(row)
        anchors.add(index + 1)
      }
      if (index < lines.length) rows.push(`[${lines.length} lines total. Continue with offset ${index + 1}.]`)
      if (lines.length === 0) rows.push('[Empty file. Insert using PUT <1:.]')
      seen.delete(path)
      seen.set(path, { hash, lines: anchors })
      if (seen.size > 128) seen.delete(seen.keys().next().value!)
      return { result: rows.join('\n') }
    } catch (error) {
      return { deny: message(error) }
    }
  })

  on('tool.run', { tool: EDIT }, async ($, e) => {
    try {
      const input = e as unknown as { path: string; tag: string; patch: string; preview?: boolean }
      const path = await resolvePath($, input.path)
      return await serial(path, async () => {
        const current = await snapshot($, path)
        const record = seen.get(path)
        if (record?.hash !== current.hash || current.hash.slice(0, 16) !== input.tag.toLowerCase()) {
          throw new Error(`Hashline snapshot is stale or unavailable. Re-read ${input.path} before editing.`)
        }
        const operations = parsePatch(input.patch, current.lines, record.lines)
        const updated = current.bom + applyPatch(current.lines, operations)
        if (byteLength(updated) > MAX_FILE_BYTES) throw new Error('The patched file would exceed 4 MiB.')
        if (updated === current.value) return { result: 'The patch leaves the file unchanged.' }
        if (input.preview) {
          const diff = capBytes(previewDiff(input.path, current.lines, operations), 40_000)
          return { result: `Preview only${diff.truncated ? ' (truncated)' : ''}\n${diff.text}` }
        }
        // shortcut: $.fs.write rewrites in place (mode, inode and hard links kept) but is not
        // atomic; the re-hash narrows the race to the write itself. Atomic temp+rename needs $.process.
        const latest = await snapshot($, path)
        if (latest.hash !== current.hash) throw new Error('File changed while applying the hashline patch. Re-read it and retry.')
        await $.fs.write(path, updated)
        seen.delete(path)
        return {
          result: `Applied ${operations.length} hashline operation(s) to ${input.path}. A subsequent edit requires a fresh read.`,
        }
      })
    } catch (error) {
      return { deny: message(error) }
    }
  })
}
