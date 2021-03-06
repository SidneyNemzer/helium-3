import express from "express";
import http from "http";
import { Server, Socket } from "socket.io";
import { v4 as uuidv4 } from "uuid";
import { Worker } from "worker_threads";
import * as path from "path";

import {
  WorkerData,
  WorkerMessageIn,
  WorkerMessageOut,
} from "./WorkerMessages";

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "http://localhost:8080",
    methods: ["GET", "POST"],
  },
});

const startWorker = () => {
  const id = uuidv4();

  const workerData: WorkerData = {
    id,
  };

  const worker = new Worker(path.resolve(__dirname, "worker.js"), {
    workerData,
  });

  worker.on("message", ([message, players]: WorkerMessageOut) => {
    if (players.length === 0) {
      // send to all players
      io.to(id).emit("message", message);
    } else {
      // send to specific players
      players.forEach((playerId) => {
        io.to(`${id}:${playerId}`).emit("message", message);
      });
    }

    if (message.type === "game-end") {
      // Game is over, the worker can be removed
      delete workers[id];
      worker.terminate();
    }
  });

  worker.on("online", () => {
    console.log("worker online", id);
  });

  worker.on("exit", () => {
    console.log("worker stopped", id);
  });

  worker.on("error", (err) => {
    console.error("error in worker", id, err);
  });

  workers[id] = worker;
  return { id, worker, playerCount: 0 };
};

const workers: { [id: string]: Worker } = {};
let pendingLobby: {
  id: string;
  worker: Worker;
  playerCount: number;
} = startWorker();

io.on("connection", (socket: Socket) => {
  console.log("player connected");
  // Player ID starts at 1
  // TODO use uuid or something more sane
  const playerId = ++pendingLobby.playerCount;

  socket.join(pendingLobby.id);
  socket.join(`${pendingLobby.id}:${playerId}`);

  const message: WorkerMessageIn = { type: "connect" };
  pendingLobby.worker.postMessage(message);

  const { worker } = pendingLobby;

  socket.on("message", (data) => {
    worker.postMessage(data);
  });

  if (pendingLobby.playerCount === 4) {
    pendingLobby = startWorker();
  }
});

export default server;
