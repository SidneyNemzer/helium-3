import test from 'ava'
import { Game } from '../game/game'
import { Robot, Tool, ActionType } from '../game/robot'
import { Point } from '../game/point'

test('hit with shield', t => {
  const robot = new Robot(<any>null, <any>null, new Point(0, 0))
  robot.tool = Tool.SHIELD
  robot.hit()
  t.false(robot.destroyed)
  t.is(robot.tool, null)
})

test('hit no shield', t => {
  t.plan(4)
  const game = <any>{
    helium3: {
      drop(point: Point, amount: number) {
        t.true(point.equals(new Point(0, 0)))
        t.is(amount, 100)
      }
    }
  }
  const robot = new Robot(<any>game, <any>{ helium3: 500 }, new Point(0, 0))
  robot.helium3 = 200
  robot.hit()
  t.true(robot.destroyed)
  t.is(robot.player.helium3, 400)
})

test('kamakazie hits adjacent robots', t => {
  const game = new Game()
  let kamakazieRobot = game.robotAt(new Point(2, 2))
  if (!kamakazieRobot) {
    return t.fail()
  }
  kamakazieRobot.action = { type: ActionType.KAMAKAZIE }
  kamakazieRobot.move()
  const destroyed1 = game.robotAt(new Point(2, 1))
  const destroyed2 = game.robotAt(new Point(1, 2))
  if (!destroyed1 || !destroyed2) {
    return t.fail()
  }
  t.plan(20)
  game.eachRobot(robot => {
    if (
      robot !== kamakazieRobot
      && robot !== destroyed1
      && robot !== destroyed2
    ) {
      t.false(robot.destroyed)
    } else {
      t.true(robot.destroyed)
    }
  })
})
