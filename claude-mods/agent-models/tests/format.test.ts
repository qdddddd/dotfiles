import { expect, test } from 'claude-code/testing'

import { formatTail, shortModel } from '../hooks/format'

test('model ids shorten to variable-style names', async () => {
  expect(shortModel('claude-opus-5-5')).toBe('opus-5.5')
  expect(shortModel('claude-opus-5-5[1m]')).toBe('opus-5.5')
  expect(shortModel('claude-haiku-4-5-20251001')).toBe('haiku-4.5')
  expect(shortModel('claude-fable-5-1')).toBe('fable-5.1')
  expect(shortModel('haiku')).toBe('haiku')
})

test('agents group by label and model', async () => {
  expect(formatTail([])).toBe('')
  expect(
    formatTail([
      { label: 'Explore', model: 'haiku-4.5' },
      { label: 'workflow', model: 'opus-5.5' },
      { label: 'workflow', model: 'opus-5.5' },
      { label: 'workflow', model: 'fable-5.1' },
    ]),
  ).toBe('Explore haiku-4.5 · 2× workflow opus-5.5 · workflow fable-5.1')
})
