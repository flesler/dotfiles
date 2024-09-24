#!/usr/bin/env node
const fs = require('fs')

let file = process.argv[2]
if (file[0] !== '/') {
  file = `${process.cwd()}/${file}`.replace(/\/\//g, '/')
}

const list = fs.readFileSync(file, 'utf8')
  .replace(/\r/g, '').trim().split(/(^|\n\n)\d+\n+/)
  .map(s => s.trim()).filter(s => !!s).map(s => {
    const [from, to, ...lines] = s.split(/\n| *--> */)
    return { from, to, text: lines.map(l => l.trim()).join(' ') }
  }).filter(sub => !!sub.text.trim())

for (let i = 0; i < list.length; i++) {
  const prev = list[i - 1]
  const sub = list[i]
  const next = list[i + 1]
  if (prev && sub.from < prev.to) {
    console.log(sub, '>', prev)
    sub.from = prev.to
  }
  if (next && sub.to > next.from) {
    console.log(sub, '<', next)
    sub.to = next.from
  }
}

const out = list.map((sub, i) => `${i + 1}\n${sub.from} --> ${sub.to}\n${sub.text}`).join('\n\n')
fs.writeFileSync(file.replace('.', '2.'), out)