import { io } from "socket.io-client";

import { Elm } from "./Client.elm";

const socket = io("http://localhost:3000");

const root = document.getElementById("root");
const app = Elm.Page.Client.init({ node: root });

app.ports.messageOut.subscribe(([action]) => {
  console.debug("client -> server:", action);
  socket.emit("message", action);
});

const createLogger = (prefix) => (data) => {
  console.log(`[${prefix}]`, data);
};

app.ports.log.subscribe(createLogger("app"));

window.app = app;

socket.on("message", (data) => {
  console.debug("server -> client", data);
  app.ports.messageIn.send(data);
});
