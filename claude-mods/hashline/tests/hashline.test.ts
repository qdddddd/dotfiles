import { expect, test } from 'claude-code/testing'

import { applyPatch, decodeUtf8, lineAnchor, linesOf, parsePatch, previewDiff } from '../hooks/hashline'

const all = (count: number) => new Set(Array.from({ length: count }, (_, index) => index + 1))
const patched = (text: string, patch: string, seen = all(linesOf(text).length)) => {
  const lines = linesOf(text)
  return applyPatch(lines, parsePatch(patch, lines, seen))
}

test('CRLF endings and a missing final newline survive replace, insert and delete', async () => {
  const text = 'a\r\nb\r\nc\r\nd'
  const [a, b, c, d] = ['a', 'b', 'c', 'd'].map((value, index) => lineAnchor(index + 1, value))
  expect(patched(text, `PUT ${b}.=${b}:\n+B\n+B2\nCUT ${c}.=${c}\nPUT >${d}:\n+e`)).toBe('a\r\nB\r\nB2\r\nd\r\ne')
  expect(patched(text, `PUT <${a}:\n+top\n`)).toBe('top\r\na\r\nb\r\nc\r\nd')
})

test('an empty file takes PUT <1: and nothing else', async () => {
  expect(patched('', 'PUT <1:\n+first\n+')).toBe('first\n\n')
  expect(() => patched('', `PUT >${lineAnchor(1, '')}:\n+x`)).toThrow(/outside the file/)
})

test('append requires the last line to have been shown', async () => {
  expect(patched('a\nb', 'PUT >$:\n+c', new Set([2]))).toBe('a\nb\nc')
  expect(() => patched('a\nb', 'PUT >$:\n+c', new Set([1]))).toThrow(/Line 2 has not been shown/)
})

test('operations that overlap or share an insertion point are refused', async () => {
  const [a, b, c] = ['a', 'b', 'c'].map((value, index) => lineAnchor(index + 1, value))
  expect(() => patched('a\nb\nc\n', `CUT ${a}.=${b}\nPUT ${b}.=${c}:\n+x`)).toThrow(/overlap/)
  expect(() => patched('a\nb\n', `PUT <${b}:\n+x\nPUT >${a}:\n+y`)).toThrow(/overlap/)
})

test('unseen interior lines cannot be edited even with valid anchors', async () => {
  const a = lineAnchor(1, 'a')
  const c = lineAnchor(3, 'c')
  expect(() => patched('a\nb\nc\n', `PUT ${a}.=${c}:\n+x`, new Set([1, 3]))).toThrow(/Line 2 has not been shown/)
})

test('a copied hash with an off-by-one line number is rejected even for identical neighbors', async () => {
  const a = lineAnchor(1, 'same')
  const wrong = a.replace(/^1#/, '2#')
  const text = 'same\nsame\n'
  expect(() => patched(text, `PUT ${a}.=${wrong}:\n+x`)).toThrow(/anchor mismatch at line 2/)
  expect(() => patched(text, `PUT >${wrong}:\n+x`)).toThrow(/anchor mismatch at line 2/)
})

test('malformed rows and missing hashes are refused', async () => {
  const a = lineAnchor(1, 'a')
  expect(() => patched('a\n', 'PUT 1.=1:\n+x')).toThrow(/Copy each N#hash/)
  expect(() => patched('a\n', 'PUT <1:\n+x')).toThrow(/Copy each N#hash/)
  expect(() => patched('a\n', `CUT ${a}.=${a}:`)).toThrow(/Invalid/)
  expect(() => patched('a\n', `PUT ${a}.=${a}:`)).toThrow(/one or more \+ lines/)
})

test('UTF-8 decoding keeps a BOM apart and rejects invalid bytes and NUL', async () => {
  expect(decodeUtf8(new Uint8Array([0xef, 0xbb, 0xbf, 0x68, 0xc3, 0xa9]))).toEqual({ value: 'hé', bom: '﻿' })
  expect(decodeUtf8(new Uint8Array([0x68, 0xc3]))).toBe(undefined)
  expect(decodeUtf8(new Uint8Array([0x68, 0x00]))).toBe(undefined)
})

test('preview diff numbers hunks against the original and the result', async () => {
  const lines = linesOf(Array.from({ length: 20 }, (_, index) => `l${index + 1}`).join('\n') + '\n')
  const b = lineAnchor(2, 'l2')
  const o = lineAnchor(15, 'l15')
  const operations = parsePatch(`PUT ${b}.=${b}:\n+X\n+Y\nCUT ${o}.=${o}`, lines, all(20))
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
