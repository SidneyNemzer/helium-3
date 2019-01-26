This file documents the messages sent between the Helium 3 client and server.

# Lobby

When a client connects to the server, it is placed in the lobby. The server waits for four players to join the lobby, then starts a new game.

| Sender | Message |
| ------ | ---- |
| Server | `{ type: 'player-count', count: 1 \| 2 \| 3 }` |
| Server | `{ type: 'game-join', id: <string>, position: PlayerIndex }` |

# Game

While in a game:

* The server will broadcast events such as player turns or countdowns
* Clients may queue actions any time after the game starts, except during player moves

## Types

```ts
// Points must be on the board, which is 20x20, 0-indexed
type Point = { x: int, y: int }

type RobotIndex = 0 | 1 | 2 | 3 | 4

type PlayerIndex = 0 | 1 | 2 | 3

type Action
  = { type: 'FIRE_MISSILE', robot: RobotIndex, target: Point }
  | { type: 'ARM_MISSILE', robot: RobotIndex, target: Point }
  | { type: 'FIRE_LASER', robot: RobotIndex, target: number }
  | { type: 'ARM_LASER', robot: RobotIndex, target: Point }
  | { type: 'SHIELD', robot: RobotIndex, target: Point }
  | { type: 'KAMAKAZIE', robot: RobotIndex }
  | { type: 'MOVE', robot: RobotIndex, target: Point }
  | { type: 'MINE', robot: RobotIndex, target: Point }
```

| Sender | Message | Notes |
| ------ | ------- | ----- |
| Server | `{ type: 'game-start', end: <timestamp> }` |  |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'FIRE_MISSILE', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'ARM_MISSILE', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'FIRE_LASER', target: number }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'ARM_LASER', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'SHIELD', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'KAMAKAZIE' }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'MOVE', target: Point }` | |
| Client | `{ type: 'queue-action', robot: RobotIndex, action: 'MINE', target: Point }` | |
| Server | `{ type: 'turn-countdown', player: PlayerIndex }` | The indicated player will move after the countdown. |
| Server | `{ type: 'move', player: PlayerIndex, actions: Action[] }` | There may be 0, 1, or 2 moves. |
| Server | `{ type: 'bad-message', reason: string }` | Sent in response to, for example, invalid JSON or an illegal move. |
