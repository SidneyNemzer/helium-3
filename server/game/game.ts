import { Player } from './player'
import { Robot } from './robot'
import { Point } from './point'
import { Helium3Map } from './helium3map'
import { EventEmitter } from 'events'

export enum CountdownType {
  START = 'START',
  END_MOVE = 'END_MOVE',
  NEXT_MOVE = 'NEXT_MOVE'
}

export const CountdownDurations = {
  [CountdownType.START]: 5000,
  [CountdownType.END_MOVE]: 2000,
  [CountdownType.NEXT_MOVE]: 4000
}

export interface Countdown {
  type: CountdownType
  timeout: NodeJS.Timeout
}

export type PlayerIndex = 0 | 1 | 2 | 3

export class Game extends EventEmitter {
  turn: PlayerIndex
  countdown: Countdown | null
  players: Player[]
  helium3: Helium3Map

  constructor() {
    super()
    this.players = [
      new Player(this, 0),
      new Player(this, 1),
      new Player(this, 2),
      new Player(this, 3)
    ]
    this.turn = 0
    this.helium3 = new Helium3Map()
    this.countdown = null
  }

  beginCountdown = (type: CountdownType, callback: () => void) => {
    this.emit('countdown', type)
    this.countdown = {
      type,
      timeout: setTimeout(callback, CountdownDurations[type])
    }
  }

  startCountdown = () => {
    this.beginCountdown(CountdownType.START, this.nextMoveCountdown)
  }

  nextMoveCountdown = () => {
    this.beginCountdown(CountdownType.NEXT_MOVE, this.moveRobots)
  }

  endMoveCountdown = () => {
    this.beginCountdown(CountdownType.END_MOVE, this.nextMoveCountdown)
  }

  moveRobots = () => {
    this.players[this.turn].move()
    if (this.turn === 3) {
      this.turn = 0
    } else {
      this.turn++
    }
    this.endMoveCountdown()
  }

  eachRobot = (fn: (robot: Robot) => any) => {
    this.players.forEach(player => player.robots.forEach(fn))
  }

  findRobot = (fn: (robot: Robot) => boolean): Robot | undefined => {
    let robot = undefined
    this.players.find(player => {
      robot = player.robots.find(fn)
      return Boolean(robot)
    })
    return robot
  }

  robotAt = (point: Point): Robot | undefined => {
    return this.findRobot(robot =>
      robot.location.x === point.x && robot.location.y === point.y
    )
  }

  hit = (point: Point): 'destroy' | 'hit' | 'empty' => {
    const robot = this.robotAt(point)
    if (robot) {
      if (robot.hit()) {
        return 'destroy'
      }
      return 'hit'
    }
    return 'empty'
  }

  /*
  TODO:
  angleIncrement and locationInLine should be replaced with some triangle math
   */

  /**
   * Translates a 45 degree angle to a direction for the x axis. Subtract 90
   * degress to get results for the y axis.
   */
  angleIncrement = (angle: number): number => {
    switch (angle) {
      case 0: return 1
      case 45: return 1
      case 90: return 0
      case 135: return -1
      case 180: return -1
      case 225: return -1
      case 270: return 0
      case 315: return 1
      default: throw new Error('angleIncrement: argument "angle" must be 0 or a multiple of 45, but it is ' + angle)
    }
  }

  /**
   * Returns a point on a line which begins at `start` and is at `angle`
   * Note: `angle` must be 0 or a multiple of 45
   */
  locationInLine = (start: Point, angle: number, index: number): Point => {
    return start.translate(
      index * this.angleIncrement(angle),
      index * this.angleIncrement(angle - 90)
    )
  }

  /**
   * Damage robots that are on the line created at start and aimed at `angle`
   * Note: `angle` must be 0 or a multiple of 45
   */
  hitInLine = (start: Point, angle: number): void => {
    const hitInLineHelp = (index: number): void => {
      const point = this.locationInLine(start, angle, index)
      // Stop if a robot absorbs the damage
      if (this.hit(point) === 'hit') {
        return
      }
      // Only continue while inside the board
      if (point.within(20, 20)) {
        return hitInLineHelp(index + 1)
      }
    }
    return hitInLineHelp(1)
  }

  toJSON = () => {
    return {
      turn: this.turn,
      players: this.players.map(player => player.toJSON()),
      helium3: this.helium3.toJSON()
    }
  }
}
