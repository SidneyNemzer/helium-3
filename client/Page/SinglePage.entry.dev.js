// Server.elm is implicitly imported here by the webpack config
import { Elm } from "./Client.elm";

// CLIENT PORTS
// log
// messageIn
// messageOut

// SERVER PORTS
// log
// messageIn
// messageOut

const seed = Math.floor(Math.random() * Number.MAX_SAFE_INTEGER);
console.log("Seed", seed);

const root1 = document.getElementById("root1");
const root2 = document.getElementById("root2");
const root3 = document.getElementById("root3");
const root4 = document.getElementById("root4");

const app1 = Elm.Page.Client.init({ node: root1 });
const app2 = Elm.Page.Client.init({ node: root2 });
const app3 = Elm.Page.Client.init({ node: root3 });
const app4 = Elm.Page.Client.init({ node: root4 });
const server = Elm.Server.init({ flags: { seed } });

const appsByPlayerId = {
  1: app1,
  2: app2,
  3: app3,
  4: app4,
};

const subscribeApp = (app) => {
  app.ports.messageOut.subscribe(([action]) => {
    console.debug("client -> server:", action);
    server.ports.messageIn.send(action);
  });
  // This page intentionally does not use onbeforeunload
  // app.ports.setPromptOnNavigation.subscribe()
};

subscribeApp(app1);
subscribeApp(app2);
subscribeApp(app3);
subscribeApp(app4);

server.ports.messageOut.subscribe(([data, players]) => {
  console.debug("server -> client:", data, players);
  if (players.length === 0) {
    app1.ports.messageIn.send(data);
    app2.ports.messageIn.send(data);
    app3.ports.messageIn.send(data);
    app4.ports.messageIn.send(data);
  } else {
    players.forEach((playerId) => {
      appsByPlayerId[playerId].ports.messageIn.send(data);
    });
  }
});

const createLogger = (prefix) => (data) => {
  console.log(`[${prefix}]`, data);
};

server.ports.log.subscribe(createLogger("server"));
app1.ports.log.subscribe(createLogger("app1"));
app2.ports.log.subscribe(createLogger("app2"));
app3.ports.log.subscribe(createLogger("app3"));
app4.ports.log.subscribe(createLogger("app4"));

// Simulate all four clients connecting
server.ports.messageIn.send({ type: "connect" });
server.ports.messageIn.send({ type: "connect" });
server.ports.messageIn.send({ type: "connect" });
server.ports.messageIn.send({ type: "connect" });

window.app1 = app1;
window.app2 = app2;
window.app3 = app3;
window.app4 = app4;
window.server = server;
