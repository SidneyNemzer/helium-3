import { io } from "socket.io-client";

import { Elm } from "./Client.elm";

const socket = io("http://localhost:3000", {
  query: { PROTOCOL_VERSION: "1" },
});

const root = document.getElementById("root");
const app = Elm.Page.Client.init({ node: root });

app.ports.messageOut.subscribe(([action]) => {
  console.debug("client -> server:", action);
  socket.emit("message", action);
});

const createLogger = (prefix) => (data) => {
  console.log(`[${prefix}]`, data);
};

const onBeforeUnload = (e) => {
  // Firefox
  e.preventDefault();
  // Chrome
  e.returnValue = "";
};

app.ports.log.subscribe(createLogger("app"));
app.ports.setPromptOnNavigation.subscribe((shouldPrompt) => {
  if (shouldPrompt) {
    window.addEventListener("beforeunload", onBeforeUnload);
  } else {
    window.removeEventListener("beforeunload", onBeforeUnload);
  }
});

window.app = app;

socket.on("message", (data) => {
  console.debug("server -> client", data);
  app.ports.messageIn.send(data);
});

socket.on("connect_error", (err) => {
  console.error("Connect Error:", err);
  app.ports.messageIn.send({ type: "connect-error", error: err.message });

  if (err.message === "PROTOCOL_VERSION_MISMATCH") {
    socket.disconnect();
  }
});
