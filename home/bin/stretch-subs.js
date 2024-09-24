#!/usr/bin/env node
const fs = require('fs')

const SEP = ' --> '

let file = process.argv[2]
if (file[0] !== '/') {
  file = `${process.cwd()}/${file}`.replace(/\/\//g, '/')
}
const lines = fs.readFileSync(file, 'utf8').split('\n')

let last
const mapped = lines.reverse().map((line) => {
  if (!line.includes(SEP)) return line

  const [start, end] = line.trim().split(SEP).map(fromTime)
  let end2 = last || end
  console.log(start, end, end2, last)
  if (last) {
    if (end2[3]) {
      end2[3]--
    } else {
      end2[2]--
      end2[3] = 999
    }
  }
  last = start.concat()
  return toTime(start) + SEP + toTime(end2)
}).reverse()

function fromTime(str) {
  return str.split(/[:,]/).map(Number)
}

function toTime(p) {
  p = p.map((s, i) => padLeft(s, '0', i === 3 ? 3 : 2))
  return `${p[0]}:${p[1]}:${p[2]},${p[3]}`
}

function padLeft(s, pad, len) {
  s = s.toString()
  while (s.length < len) s = pad + s
  return s
}

fs.writeFileSync(file.replace('.', '-s.'), mapped.join('\n'))
