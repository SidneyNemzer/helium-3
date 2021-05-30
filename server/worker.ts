import { workerData, parentPort } from "worker_threads";

import {
  WorkerOptions,
  WorkerMessageIn,
  WorkerMessageOut,
} from "./worker-types";
import { Elm } from "./Server.js";

const { id } = workerData as WorkerOptions;

if (!parentPort) {
  throw new Error("missing parentPort");
}

// re-assigning allows typescript to infer the correct type in functions
const port = parentPort;

const seed = Math.floor(Math.random() * Number.MAX_SAFE_INTEGER);
const server = Elm.Server.init({ flags: { seed } });

server.ports.messageOut.subscribe(([data, players]: WorkerMessageOut) => {
  port.postMessage([data, players]);
});

port.on("message", (event: WorkerMessageIn) => {
  server.ports.messageIn.send(event);
});
