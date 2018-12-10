import { Game } from './game'
import { Point } from './point'
import { Player } from './player'

export enum ActionType {
  FIRE_MISSILE = 'FIRE_MISSILE',
  ARM_MISSILE = 'ARM_MISSILE',
  FIRE_LASER = 'FIRE_LASER',
  ARM_LASER = 'ARM_LASER',
  SHIELD = 'SHIELD',
  KAMAKAZIE = 'KAMAKAZIE',
  MOVE = 'MOVE',
  MINE = 'MINE'
}

export type Action
  = { type: ActionType.FIRE_MISSILE, target: Point }
  | { type: ActionType.ARM_MISSILE, target: Point }
  | { type: ActionType.FIRE_LASER, target: number }
  | { type: ActionType.ARM_LASER, target: Point }
  | { type: ActionType.SHIELD, target: Point }
  | { type: ActionType.KAMAKAZIE }
  | { type: ActionType.MOVE, target: Point }
  | { type: ActionType.MINE, target: Point }

export enum Tool {
  MISSILE = 'MISSILE',
  LASER = 'LASER',
  SHIELD = 'SHIELD'
}

export class Robot {
  location: Point
  tool: Tool | null
  action: Action | null
  game: Game
  player: Player
  helium3: number
  destroyed: boolean

  constructor(game: Game, player: Player, start: Point) {
    this.location = start
    this.tool = null
    this.action = null
    this.game = game
    this.helium3 = 0
    this.player = player
    this.destroyed = false
  }

  /**
   * Returns the current target of the robot, or null if the robot has no target,
   * or the target is not a single point
   */
  target(): Point | null {
    if (
      this.action
      && this.action.type !== ActionType.KAMAKAZIE
      && this.action.type !== ActionType.FIRE_LASER
    ) {
      return this.action.target
    }
    return null
  }

  move() {
    const { action } = this
    if (!action) {
      return
    }
    this.action = null
    const location = this.location

    switch (action.type) {
      case ActionType.FIRE_MISSILE:
        this.tool = null
        this.game.hit(action.target)
        break

      case ActionType.ARM_MISSILE:
        this.tool = Tool.MISSILE
        this.location = action.target
        break

      case ActionType.FIRE_LASER:
        this.tool = null
        this.game.hitInLine(this.location, action.target)
        break

      case ActionType.ARM_LASER:
        this.tool = Tool.LASER
        this.location = action.target
        break

      case ActionType.SHIELD:
        this.tool = Tool.SHIELD
        this.location = action.target
        break

      case ActionType.KAMAKAZIE:
        const robotsAround = <Robot[]> this.location
            .around(true)
            .map(this.game.robotAt)
            .filter(Boolean) // TypeScript doesn't understand this so we have to cast to <Robot[]>
        robotsAround
          .forEach((robot: Robot) => {
            robot.hit()
          })
        break

      case ActionType.MOVE:
        this.location = action.target
        this.tool = null
        break

      case ActionType.MINE:
        this.location = action.target
        this.tool = null
        const mined = this.game.helium3.mine(action.target)
        this.helium3 += mined
        this.player.helium3 += mined
        break
    }

    if (this.location !== location) {
      this.game.eachRobot(robot => {
        if (robot !== this && robot.target() === location) {
          robot.action = null
        }
      })
    }
  }

  /**
   * Damages the robot, possibly destroying it
   */
  hit(): boolean {
    if (this.tool === Tool.SHIELD) {
      this.tool = null
      return false
    }
    const lostHelium3 = this.helium3 * 0.5
    this.destroyed = true
    this.player.helium3 -= lostHelium3
    this.game.helium3.drop(this.location, lostHelium3)
    return true
  }

  toJSON() {
    return {
      location: this.location,
      tool: this.tool,
      action: this.action,
      helium3: this.helium3,
      destroyed: this.destroyed
    }
  }
}
