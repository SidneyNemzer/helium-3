import express from "express";
import http from "http";
import { Server, Socket } from "socket.io";
import { v4 as uuidv4 } from "uuid";
import { Worker } from "worker_threads";
import * as path from "path";

import {
  WorkerOptions,
  WorkerMessageIn,
  WorkerMessageOut,
} from "./worker-types";

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "http://localhost:8080",
    methods: ["GET", "POST"],
  },
});

type Lobby = {
  id: string;
  worker: Worker;
  numPlayers: number;
};

const lobbies: { [id: string]: Lobby | undefined } = {};

const startWorker = (): Lobby => {
  const id = uuidv4();

  const workerData: WorkerOptions = {
    id,
  };

  const worker = new Worker(path.resolve(__dirname, "worker.js"), {
    workerData,
  });

  worker.on("message", ([message, players]: WorkerMessageOut) => {
    if (players.length === 0) {
      // send to all players
      io.to(`lobby:${id}`).emit("message", message);
    } else {
      // send to specific players
      players.forEach((playerId) => {
        io.to(`lobby:${id}:${playerId}`).emit("message", message);
      });
    }

    if (message.type === "game-join") {
      // lobby is full and game has started
      if (pendingLobby.id === id) {
        pendingLobby = startWorker();
      }
    }

    if (message.type === "game-end") {
      // Game is over, the worker can be removed
      delete lobbies[id];
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

  const lobby = { id, worker, numPlayers: 0 };
  lobbies[id] = lobby;
  return lobby;
};

let pendingLobby: Lobby = startWorker();

const getLobby = (socket: Socket): Lobby | undefined => {
  const lobbyRoom = Array.from(socket.rooms).find((room) =>
    room.startsWith("lobby:")
  );
  if (!lobbyRoom) {
    return;
  }

  const [_, lobbyId] = lobbyRoom.split(":");
  if (!lobbyId) {
    return;
  }

  const lobby = lobbies[lobbyId];
  return lobby;
};

const leaveLobby = (socket: Socket) => {
  // Lobby must be found before leaving rooms
  const lobby = getLobby(socket);

  // Even if the lobby is not found (the game may have ended), try leaving lobbies.
  socket.rooms.forEach((room) => {
    if (room.startsWith("lobby:")) {
      socket.leave(room);
    }
  });

  if (!lobby) {
    return;
  }

  console.log("player", socket.id, "left lobby", lobby.id);

  lobby.numPlayers--;

  const message: WorkerMessageIn = { type: "disconnect" };
  lobby.worker.postMessage(message);

  if (lobby.numPlayers === 0 && pendingLobby.id !== lobby.id) {
    console.log("stopping worker", lobby.id, "beacuse all players left");
    delete lobbies[lobby.id];
    lobby.worker.terminate();
  }
};

const joinLobby = (socket: Socket) => {
  const { id, worker } = pendingLobby;
  console.log("player", socket.id, "connected to lobby", id);

  // Player ID starts at 1
  // TODO use uuid or something more sane
  const playerId = ++pendingLobby.numPlayers;

  socket.join(`lobby:${id}`);
  socket.join(`lobby:${id}:${playerId}`);

  const message: WorkerMessageIn = { type: "connect" };
  worker.postMessage(message);

  if (pendingLobby.numPlayers === 4) {
    pendingLobby = startWorker();
  }
};

io.on("connection", (socket: Socket) => {
  console.log("socket connect", socket.id);

  joinLobby(socket);

  socket.on("message", (data: WorkerMessageIn) => {
    if (
      data.type === "new-lobby" &&
      !socket.rooms.has(`lobby:${pendingLobby.id}`)
    ) {
      // The client has requested a new lobby
      leaveLobby(socket);
      joinLobby(socket);
    } else {
      const lobby = getLobby(socket);
      if (!lobby) {
        console.log(
          "dropping message because lobby could not be located",
          socket.id,
          socket.rooms
        );
        return;
      }
      lobby.worker.postMessage(data);
    }
  });

  socket.on("disconnecting", () => {
    console.log("socket disconnecting");
    leaveLobby(socket);
  });
});

export default server;
