const fs = require('fs')

//  inotifywait -qmre modify,create,delete,move . |  node ~/bin/inotifysync.js /media/flesler/Data/Code/unreal/unreal-gql

const DEST = process.argv[2]
const DELAY = 500

let timeout
let buf = ''

process.stdin.setEncoding('utf8')
process.stdin.on('data', (data) => {
  buf += data
  if (!data.includes('\n')) {
    return
  }

  clearTimeout(timeout)
  timeout = setTimeout(parse, DELAY)
})

function parse() {
  const lines = buf.split('\n')
  buf = lines.pop()

  let last
  lines.forEach((line) => {
    const [dir, action, file] = line.split(' ')
    if (file.includes('.lock')) {
      return
    }
    const path = `${dir.replace('./', '')}${file}`
    if (path === last) {
      return
    }
    last = path
    const dest = `${DEST}/${path}`
    console.log('>', action, dest)
    try {
      switch (action) {
        case 'CREATE':
        case 'MODIFY':
        case 'MOVED_TO':
          return fs.copyFileSync(path, dest)
        case 'DELETE':
        case 'MOVED_FROM':
        case 'DELETE,ISDIR':
          return rm(dest)
      }
    } catch (err) {
      console.error('> Failed', action, dest, err.message)
    }
  })
}

function rm(dest) {
  const stat = fs.statSync(dest)
  if (stat.isDirectory()) {
    for (const file of fs.readdirSync(dest)) {
      rm(`${dest}/${file}`)
    }
    fs.rmdirSync(dest)
  } else if (stat.isFile()) {
    fs.unlinkSync(dest)
  }
}