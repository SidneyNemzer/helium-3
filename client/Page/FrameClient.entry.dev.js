import { Elm } from "./Client.elm";

const root = document.getElementById("root");
const app = Elm.Page.Client.init({ node: root });

app.ports.messageOut.subscribe(([action]) => {
  console.debug("client -> server:", action);
  parent.postMessage({ ...action, h3: true }, window.location.origin);
});

const createLogger = (prefix) => (data) => {
  console.log(`[${prefix}]`, data);
};

app.ports.log.subscribe(createLogger("app"));
// This page intentionally does not use onbeforeunload
// app.ports.setPromptOnNavigation.subscribe()

window.app = app;

window.addEventListener("message", (event) => {
  if (event.origin !== window.location.origin || !event.data.h3) {
    return;
  }

  app.ports.messageIn.send(event.data);
});

console.debug("client -> server:", { type: "connect", h3: true });
parent.postMessage({ type: "connect", h3: true }, window.location.origin);
