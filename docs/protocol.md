This file documents the messages sent between the client and server during a game.

# Lobby

The server waits for four players to join the lobby, then starts a new game.

| Direction | Type | Data | Notes |
| :-------- | :--- | ---- | ----- |
| to client | `player-count` | integer from 1 to 4 | |
| to client | `game-join` | `{ gameId: string, playerIndex: number }` | |

# Game

During a game, clients may queue actions for their robots at any time. The server executes the actions on the player's turn. The server periodically sends state updates, which the client should use to sync with it's local state, potentially animating changes (such as robots moving).

```
type Point = { x: number, y: number }

type RobotIndex = 0 | 1 | 2 | 3 | 4

type QueueAction
  = { robot: RobotIndex, type: 'FIRE_MISSILE', target: Point }
  | { robot: RobotIndex, type: 'ARM_MISSILE', target: Point }
  | { robot: RobotIndex, type: 'FIRE_LASER', target: number }
  | { robot: RobotIndex, type: 'ARM_LASER', target: Point }
  | { robot: RobotIndex, type: 'SHIELD', target: Point }
  | { robot: RobotIndex, type: 'KAMAKAZIE' }
  | { robot: RobotIndex, type: 'MOVE', target: Point }
  | { robot: RobotIndex, type: 'MINE', target: Point }

type Countdown
  = { type: 'START', time: number }
  | { type: 'END_MOVE', time: number }
  | { type: 'NEXT_MOVE', time: number }
```

| Direction | Type | Data | Notes |
| :-------- | :--- | ---- | ----- |
| to server | `queue-move` | `QueueAction` | |
| to client | `state-update` | `Game` | |
| to client | `countdown` | `Countdown` | |
| to client | `validation-error` | string | Indicates a protocol violation |
