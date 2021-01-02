import uuid from "uuid/v1";
import { Socket, Server } from "socket.io";
import { GameController } from "./game-controller";

const queue: Socket[] = [];

export class Queue {
  io: Server;
  constructor(io: Server) {
    this.io = io;
  }

  onConnect(socket: Socket) {
    socket.on("disconnect", this.onDisconnect);
    queue.push(socket);
    socket.join("waiting");
    socket.to("waiting").emit("queue-change", queue.length);
    console.log(`Player joined queue (queue.length: ${queue.length})`);
    if (queue.length === 4) {
      this.createGame(queue.splice(0, 4));
    }
  }

  createGame(sockets: Socket[]) {
    const gameId = uuid();
    console.log("Creating game", gameId);
    sockets.forEach((socket, index) => {
      socket.join(gameId);
      socket.emit("game-join", { gameId, playerIndex: index });
    });
    new GameController(this.io, gameId, sockets);
  }

  onDisconnect(socket: Socket) {
    const queueIndex = queue.findIndex(({ id }) => id === socket.id);
    if (queueIndex > -1) {
      queue.splice(queueIndex, queueIndex + 1);
      socket.to("waiting").emit("queue-change", queue.length);
      console.log(`Player left queue (queue.length: ${queue.length})`);
    } else {
      console.log("Player left game");
    }
  }
}
