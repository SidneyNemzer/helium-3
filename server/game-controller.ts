import { Server, Socket } from 'socket.io'
import { Game, CountdownType, PlayerIndex } from './game/game'
import { Action } from './game/robot'
import * as t from 'io-ts'

const PointValidator = t.type({
  x: t.number,
  y: t.number
})

const RobotIndexValidator = t.union([
  t.literal(0),
  t.literal(1),
  t.literal(2),
  t.literal(3),
  t.literal(4)
])

const FireMissileValidator = t.type({
  type: t.literal('FIRE_MISSILE'),
  robot: RobotIndexValidator,
  target: PointValidator
})

const ArmMissileValidator = t.type({
  type: t.literal('ARM_MISSILE'),
  robot: RobotIndexValidator,
  target: PointValidator
})

const FireLaserValidator = t.type({
  type: t.literal('FIRE_LASER'),
  robot: t.number,
  target: PointValidator
})

const ArmLaserValidator = t.type({
  type: t.literal('ARM_LASER'),
  robot: RobotIndexValidator,
  target: PointValidator
})

const ShieldValidator = t.type({
  type: t.literal('SHIELD'),
  robot: RobotIndexValidator,
  target: PointValidator
})

const KamakazieValidator = t.type({
  type: t.literal('KAMAKAZIE'),
  robot: RobotIndexValidator
})

const MoveValidator = t.type({
  type: t.literal('MOVE'),
  robot: RobotIndexValidator,
  target: PointValidator
})

const MineValidator = t.type({
  type: t.literal('MINE'),
  robot: RobotIndexValidator,
  target: PointValidator
})

const QueueActionValidator = t.taggedUnion(
  'type',
  [
    FireMissileValidator,
    ArmMissileValidator,
    FireLaserValidator,
    ArmLaserValidator,
    ShieldValidator,
    KamakazieValidator,
    MoveValidator,
    MineValidator
  ],
  'queue action'
)

interface IndexedSocket extends Socket {
  playerIndex: PlayerIndex
}

export class GameController {
  io: Server
  gameId: string
  sockets: IndexedSocket[]
  game: Game

  constructor(io: Server, id: string, sockets: Socket[]) {
    this.io = io
    this.gameId = id
    this.sockets = sockets
      .map((socket: Socket, index: number) => {
        (<IndexedSocket> socket).playerIndex = <PlayerIndex>index
        return <IndexedSocket> socket
      })
    this.game = new Game()

    this.game.on('countdown', this.onCountdown)
    this.sockets.forEach(this.attachSocketListeners)
  }

  emit = (type: string, ...args: any[]) => {
    this.io.to(this.gameId).emit(type, ...args)
  }

  onCountdown = (type: CountdownType) => {
    this.emit('countdown', type)
  }

  attachSocketListeners = (socket: IndexedSocket) => {
    socket.on('queue-move', data => this.onQueueMove(socket, data))
  }

  onQueueMove = (socket: IndexedSocket, data: any) => {
    // TODO We're checking the shape but not valid moves
    QueueActionValidator
      .decode(data)
      .fold(
        errors => {
          console.error('validation errors', data, errors)
          socket.emit('validation-error')
        },
        (action: t.TypeOf<typeof QueueActionValidator>) => {
          const { robot, ...actionNoRobot } = action
          this.game.players[socket.playerIndex]
            .robots[robot].action = <Action>actionNoRobot
        }
      )
  }
}
