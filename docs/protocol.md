The Helium 3 client and server communicate using Socket.IO. The underlying protocol is implemented by Socket.IO. Messages sent over Socket.IO use the following format.

# Types

```ts
// Points must be on the board, which is 20x20, 0-indexed
type Point = { x: number; y: number };

type Direction = { vX: number; vY: number };

type RobotId = number;

type PlayerIndex = 0 | 1 | 2 | 3;

type Timestamp = number;

type HeliumGrid = {
  width: number;
  height: number;
  data: Int[];
};

// Server actions include hidden state like enemy robots that were hit by a
// weapon but had a shield
type ServerAction =
  // `shield` indicates if the target had their shield armed
  | { type: "FIRE_MISSILE"; robot: RobotId; target: Point; shield: Bool }
  | { type: "ARM_MISSILE"; robot: RobotId; target: Point }
  // if the laser was stopped, that robot was shielded. all robots in the laser
  // path up to `stoppedBy` are destroyed
  | {
      type: "FIRE_LASER";
      robot: RobotId;
      target: Direction;
      stoppedBy: ?RobotId;
    }
  | { type: "ARM_LASER"; robot: RobotId; target: Point }
  // robots that are in range but not `destroyed` were shielded
  | { type: "SELF_DESTRUCT"; robot: RobotId; destroyed: RobotId[] }
  | { type: "MOVE"; robot: RobotId; target: Point }
  // Only the owner sees their robot's shields. Other players just receive a "move" action.
  | { type: "SHIELD"; robot: RobotId; target: Point }
  | { type: "MINE"; robot: RobotId; target: Point };

type ClientAction =
  | { action: "FIRE_MISSILE"; robot: RobotId; target: Point }
  | { action: "ARM_MISSILE"; robot: RobotId; target: Point }
  | { action: "FIRE_LASER"; robot: RobotId; target: number }
  | { action: "ARM_LASER"; robot: RobotId; target: Point }
  | { action: "SHIELD"; robot: RobotId; target: Point }
  | { action: "SELF_DESTRUCT"; robot: RobotId }
  | { action: "MOVE"; robot: RobotId; target: Point }
  | { action: "MINE"; robot: RobotId; target: Point };
```

# Lobby

When a client connects to the server, it is placed in the lobby. The server waits for four players to join the lobby, then starts a new game. Games last for a limited number of turns, where each player gets the same number of turns. The server specifies this number in the `game-join` message.

After the game ends, the client must specify it's ready to join a new game with `new-lobby`. `new-lobby` is only needed after the game ends, the client is automatically added to a lobby when the client connects. `new-lobby` does nothing if the client is already in a lobby.

`lobby-join` is sent just after joining a lobby. `lobby-join` distinguishes from network interruptions and server restarts. When `lobby-join` is received, the client should assume the game has reset, and should return to the lobby.

| Sender | Message                                                                                       |
| ------ | --------------------------------------------------------------------------------------------- |
| Server | `{ type: 'lobby-join', id: string }`                                                          |
| Server | `{ type: 'player-count', count: 1 \| 2 \| 3, playerId: PlayerIndex }`                         |
| Server | `{ type: 'game-join', id: string, position: PlayerIndex, helium: HeliumGrid, turns: number }` |
| Client | `{ type: 'new-lobby' }`                                                                       |

# Game

While in a game:

- The server will broadcast events such as player turns or countdowns.
- After the game starts, clients can queue actions. Actions may not be queued while a player is moving.
- Clients are automatically removed from the game after it ends.
- After the `game-end` message, no more messages are accepted or sent by the server.

| Sender | Message                                                            | Notes                                                                                                           |
| ------ | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| Client | `{ type: 'queue', action: ClientAction }`                          |                                                                                                                 |
| Server | `{ type: 'action-countdown', player: PlayerIndex }`                | The indicated player will move after the countdown. Clients must wait for the `action` message for the actions. |
| Server | `{ type: 'action', player: PlayerIndex, actions: ServerAction[] }` | There may be 0, 1, or 2 moves.                                                                                  |
| Server | `{ type: 'game-end' }`                                             |                                                                                                                 |

# Errors

The server will respond with `{ type: 'bad-message', reason: string }` for malformed or invalid messages. For example, a message with no `type` field, or `{ type: 'queue-action', robot: RobotId, action: 'SHIELD', target: { x: 10, y: -1 } }` (the target is not on the board).

Clients should carefully validate actions before sending, for example, a player cannot queue two of their robots to move to the same square. However, two different players may queue one of their robots to the same square. The player with the first turn gets to move, the later player's action is reset.

# Diagram

```plantuml
@startuml
== Lobby ==

loop until lobby fills
  Server -> Client : player count
  note right
    "count" may not
    increase, players can leave
    the lobby
  end note
end

...

Server -> Client : game join
note right
  game should start after lobby
  fills, but client must wait for
  the "game join" message
end note

== Game ==

...

Server -> Client : game start
note right
  similar to "game join", client must
  wait for "game start" to start
  the timer
end note

...

loop game
  Client -> Server : action\n(details ...)

  note right
    actions can be queued at any
    time during the game
  end note

  group turn
    Server -> Client : turn countdown

    Server -> Client : server action

    note right
      server tells clients about
      the next player's actions right
      before their turn.
    end note
  end
end

Server -> Client : game end

@enduml
```
