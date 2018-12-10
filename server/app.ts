import express from 'express'
import http from 'http'
import socketio from 'socket.io'
import { Queue } from './queue'

const app = express()
const server = http.createServer(app)
const io = socketio(server)
const queue = new Queue(io)

app.get('/', (req, res) => {
  /* eslint-disable indent */
  res.type('html').send(
`<!DOCTYPE html>
<html>
  <head>
    <script src="/socket.io/socket.io.js"></script>
    <script>
      socket = io()
    </script>
  </head>
</html>`
  )
  /* eslint-enable indent */
})

export default server
