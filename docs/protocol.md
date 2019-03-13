The Helium 3 client and server communicate with JSON over a web socket.

# Types

```ts
// Points must be on the board, which is 20x20, 0-indexed
type Point = { x: number, y: number }

type RobotIndex = 0 | 1 | 2 | 3 | 4

type PlayerIndex = 0 | 1 | 2 | 3

type Timestamp = number

type ServerAction
  = { type: 'FIRE_MISSILE', robot: RobotIndex, target: Point, shield: Bool }
  | { type: 'ARM_MISSILE', robot: RobotIndex, target: Point }
  | { type: 'FIRE_LASER', robot: RobotIndex, target: number, stoppedBy: false | RobotIndex }
  | { type: 'ARM_LASER', robot: RobotIndex, target: Point }
  | { type: 'SHIELD', robot: RobotIndex, target: Point }
  | { type: 'KAMAKAZIE', robot: RobotIndex, shield: RobotIndex[] }
  | { type: 'MOVE', robot: RobotIndex, target: Point }
  | { type: 'MINE', robot: RobotIndex, target: Point };
```

# Lobby

When a client connects to the server, it is placed in the lobby. The server waits for four players to join the lobby, then starts a new game.

| Sender | Message |
| ------ | ------- |
| Server | `{ type: 'player-count', count: 1 \| 2 \| 3 }` |
| Server | `{ type: 'game-join', id: string, position: PlayerIndex }` |

# Game

While in a game:

* The server will broadcast events such as player turns or countdowns
* After the game starts, clients can queue actions. Actions may not be queued while a player is moving.
* Clients are automatically removed from the game after it ends

| Sender | Message | Notes |
| ------ | ------- | ----- |
| Server | `{ type: 'game-start', end: Timestamp }` |  |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'FIRE_MISSILE', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'ARM_MISSILE', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'FIRE_LASER', target: number }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'ARM_LASER', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'SHIELD', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'KAMAKAZIE' }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'MOVE', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'MINE', target: Point }` | |
| Server | `{ type: 'action-countdown', player: PlayerIndex }` | The indicated player will move after the countdown. Clients must wait for the `action` message for the actions. |
| Server | `{ type: 'action', player: PlayerIndex, actions: ServerAction[] }` | There may be 0, 1, or 2 moves. |

# Errors

The server will respond with `{ type: 'bad-message', reason: string }` for malformed or invalid messages. For example, a message with no `type` field, or `{ type: 'queue-action', robot: RobotIndex, action: 'SHIELD', target: { x: 10, y: -1 } }` (the target is not on the board).

Clients should carefully validate actions before sending, for example, a player cannot queue two of their robots to move to the same square. However, two different players may queue one of their robots to the same square. The player with the first turn gets to move, the later player's action is reset.
