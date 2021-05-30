import { Elm } from "../Server.elm";

const seed = Math.floor(Math.random() * Number.MAX_SAFE_INTEGER);
console.log("Seed", seed);

const server = Elm.Server.init({ flags: { seed } });
// IDs start at 1
// Value is the window object of the frame
const appsByPlayerId = {};

server.ports.messageOut.subscribe(([data, players]) => {
  console.debug("server -> client:", data, players);
  if (players.length === 0) {
    // send to all
    Object.values(appsByPlayerId).map((w) => {
      w.postMessage({ ...data, h3: true }, window.location.origin);
    });
  } else {
    // send to specific players
    players.forEach((playerId) => {
      if (!appsByPlayerId[playerId]) {
        return;
      }
      appsByPlayerId[playerId].postMessage(
        { ...data, h3: true },
        window.location.origin
      );
    });
  }
});

const createLogger = (prefix) => (data) => {
  console.log(`[${prefix}]`, data);
};

server.ports.log.subscribe(createLogger("server"));

window.server = server;

window.addEventListener("message", (event) => {
  if (event.origin !== window.location.origin || !event.data.h3) {
    return;
  }

  if (!Object.values(appsByPlayerId).includes(event.source)) {
    const id = Object.keys(appsByPlayerId).length + 1;
    console.debug("adding player", id);
    appsByPlayerId[id] = event.source;
  }

  server.ports.messageIn.send(event.data);
});
