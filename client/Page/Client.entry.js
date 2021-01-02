// Server.elm is implicitly imported here by the webpack config
import { Elm } from "./Client.elm";

// CLIENT PORTS
// endTurn_
// receiveServerAction_
// sendClientAction_

// SERVER PORTS
// onEndTurn_
// log
// receiveClientAction_
// sendServerAction_

const root1 = document.getElementById("root1");
const root2 = document.getElementById("root2");
const root3 = document.getElementById("root3");
const root4 = document.getElementById("root4");

const app1 = Elm.Page.Client.init({ node: root1, flags: { player: 1 } });
const app2 = Elm.Page.Client.init({ node: root2, flags: { player: 2 } });
const app3 = Elm.Page.Client.init({ node: root3, flags: { player: 3 } });
const app4 = Elm.Page.Client.init({ node: root4, flags: { player: 4 } });
const server = Elm.Server.init();

const appsByPlayerId = {
  1: app1,
  2: app2,
  3: app3,
  4: app4,
};

const subscribeApp = (app) => {
  app.ports.endTurn_.subscribe(() => {
    server.ports.onEndTurn_.send(null);
  });

  app.ports.sendClientAction_.subscribe((action) => {
    server.ports.receiveClientAction_.send(action);
  });
};

subscribeApp(app1);
subscribeApp(app2);
subscribeApp(app3);
subscribeApp(app4);

server.ports.log.subscribe((data) => {
  console.log("[Server]", data);
});

server.ports.sendServerAction_.subscribe(([players, data]) => {
  if (players.length === 0) {
    app1.ports.receiveServerAction_.send(data);
    app2.ports.receiveServerAction_.send(data);
    app3.ports.receiveServerAction_.send(data);
    app4.ports.receiveServerAction_.send(data);
  } else {
    players.forEach((playerId) => {
      debugger;
      appsByPlayerId[playerId].ports.receiveServerAction_.send(data);
    });
  }
});

window.app1 = app1;
window.app2 = app2;
window.app3 = app3;
window.app4 = app4;
window.server = server;
