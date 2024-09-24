#!/usr/bin/env node
// Disable the laptop's keyboard since it's leaking keystrokes (F12)
// @see https://hirazone.medium.com/how-to-disable-laptop-keyboard-on-ubuntu-59f7b7b81727
const spawnSync = require('child_process').spawnSync

const DISABLE = '--disable'
const KEYBOARD = 'Mechanical Gaming Keyboard'
// TODO: Remove the hotkeys
const BUILTIN = ['Dell WMI hotkeys', 'AT Translated Set', 'DELL Wireless hotkeys']

let option = process.argv[2] || DISABLE

const { stdout, error } = spawnSync('xinput', ['--list'], { encoding: 'utf8' })
if (error) {
  console.error(error.message)
  process.exit(1)
}

const devices = stdout.split('\n')
const isDetected = devices.some(d => d.includes(KEYBOARD))
if (option === DISABLE && !isDetected) {
  console.log(`WARNING: No ${KEYBOARD} detected, enabling`)
  option = '--enable'
}
for (const device of devices) {
  const isBuiltin = BUILTIN.some(s => device.includes(s))
  if (!isBuiltin) {
    continue
  }
  const id = device.split(/\s+/).find(s => s.includes('id=')).split('=')[1]
  if (!id) {
    console.warn('No id found for device', device)
    continue
  }
  // console.log('$', 'xinput', option, id)
  spawnSync('xinput', [option, id])
}
