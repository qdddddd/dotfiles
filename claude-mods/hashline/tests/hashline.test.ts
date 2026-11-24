import { expect, test } from 'claude-code/testing'

import { applyPatch, decodeUtf8, linesOf, parsePatch, previewDiff } from '../hooks/hashline'

const all = (count: number) => new Set(Array.from({ length: count }, (_, index) => index + 1))
const patched = (text: string, patch: string, seen = all(linesOf(text).length)) => {
  const lines = linesOf(text)
  return applyPatch(lines, parsePatch(patch, lines.length, seen))
}

test('CRLF endings and a missing final newline survive replace, insert and delete', async () => {
  const text = 'a\r\nb\r\nc\r\nd'
  expect(patched(text, 'PUT 2.=2:\n+B\n+B2\nCUT 3.=3\nPUT >4:\n+e')).toBe('a\r\nB\r\nB2\r\nd\r\ne')
  expect(patched(text, 'PUT <1:\n+top\n')).toBe('top\r\na\r\nb\r\nc\r\nd')
})

test('an empty file takes PUT <1: and nothing else', async () => {
  expect(patched('', 'PUT <1:\n+first\n+')).toBe('first\n\n')
  expect(() => patched('', 'PUT >1:\n+x')).toThrow(/outside the file/)
})

test('operations that overlap or share an insertion point are refused', async () => {
  expect(() => patched('a\nb\nc\n', 'CUT 1.=2\nPUT 2.=3:\n+x')).toThrow(/overlap/)
  expect(() => patched('a\nb\n', 'PUT <2:\n+x\nPUT >1:\n+y')).toThrow(/overlap/)
})

test('lines not shown for the snapshot cannot be anchored', async () => {
  expect(() => patched('a\nb\nc\n', 'PUT 2.=3:\n+x', new Set([1, 2]))).toThrow(/Line 3 has not been shown/)
})

test('malformed rows are refused', async () => {
  expect(() => patched('a\n', 'PUT 1.=1')).toThrow(/Invalid/)
  expect(() => patched('a\n', 'CUT 1.=1:')).toThrow(/Invalid/)
  expect(() => patched('a\n', 'PUT 1.=1:')).toThrow(/one or more \+ lines/)
})

test('UTF-8 decoding keeps a BOM apart and rejects invalid bytes and NUL', async () => {
  expect(decodeUtf8(new Uint8Array([0xef, 0xbb, 0xbf, 0x68, 0xc3, 0xa9]))).toEqual({ value: 'hé', bom: '﻿' })
  expect(decodeUtf8(new Uint8Array([0x68, 0xc3]))).toBe(undefined)
  expect(decodeUtf8(new Uint8Array([0x68, 0x00]))).toBe(undefined)
})

test('preview diff numbers hunks against the original and the result', async () => {
  const lines = linesOf(Array.from({ length: 20 }, (_, index) => `l${index + 1}`).join('\n') + '\n')
  const operations = parsePatch('PUT 2.=2:\n+X\n+Y\nCUT 15.=15', lines.length, all(20))
  expect(previewDiff('f', lines, operations).split('\n')).toEqual([
    '--- f',
    '+++ f',
    '@@ -1,5 +1,6 @@',
    ' l1',
    '-l2',
    '+X',
    '+Y',
    ' l3',
    ' l4',
    ' l5',
    '@@ -12,7 +13,6 @@',
    ' l12',
    ' l13',
    ' l14',
    '-l15',
    ' l16',
    ' l17',
    ' l18',
  ])
})
