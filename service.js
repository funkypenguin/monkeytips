'use strict'

const TurtleCoind = require('./')
const util = require('util')

var daemon = new TurtleCoind({
  // Load additional daemon parameters here
   dataDir: '/var/lib/monkeytips', // Where do you store your blockchain?
   // pollingInterval: 10000, // How often to check the daemon in milliseconds
   // maxPollingFailures: 5, // How many polling intervals can fail before we emit a down event?
   path: './monkeytipsd', // Where can I find TurtleCoind?
   dataDir: '/var/lib/monkeytips', // Where do you store your blockchain?
   rpcBindPort: '13002',
   p2pBindPort: '13001'
})

function log (message) {
  console.log(util.format('%s: %s', (new Date()).toUTCString(), message))
}

daemon.on('start', (args) => {
  log(util.format('monkeytipsd has started... %s', args))
})

daemon.on('started', () => {
  log('monkeytipsd is attempting to synchronize with the network...')
})

daemon.on('syncing', (info) => {
  log(util.format('monkeytipsd has syncronized %s out of %s blocks [%s%]', info.height, info.network_height, info.percent))
})

daemon.on('synced', () => {
  log('monkeytipsd is synchronized with the network...')
})

daemon.on('ready', (info) => {
  log(util.format('monkeytipsd is waiting for connections at %s @ %s - %s H/s', info.height, info.difficulty, info.globalHashRate))
})

daemon.on('desync', (daemon, network, deviance) => {
  log(util.format('monkeytipsd is currently off the blockchain by %s blocks. Network: %s  Daemon: %s', deviance, network, daemon))
})

daemon.on('down', () => {
  log('monkeytipsd is not responding... stopping process...')
  daemon.stop()
})

daemon.on('stopped', (exitcode) => {
  log(util.format('monkeytipsd has closed (exitcode: %s)... restarting process...', exitcode))
  daemon.start()
})

daemon.on('info', (info) => {
  log(info)
})

daemon.on('error', (err) => {
  log(err)
})

daemon.start()
