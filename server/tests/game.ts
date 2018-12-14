import test from 'ava'
import { Game } from '../game/game'
import { ActionType, Tool } from '../game/robot'
import { Point } from '../game/point'

test('creates four players and 20 robots', t => {
  const game = new Game()
  t.is(game.players.length, 4)
  game.players.map(player => {
    t.is(player.robots.length, 5)
  })
})

test('moveRobots', t => {
  t.plan(5)
  const game = new Game()
  const robot = game.players[0].robots[0]
  robot.action = {
    type: ActionType.ARM_LASER,
    target: new Point(10, 10)
  }
  game.endMoveCountdown = () => {
    t.pass()
  }
  game.moveRobots()

  t.is(game.turn, 1)
  t.is(robot.action, null)
  t.deepEqual(robot.location, new Point(10, 10))
  t.is(robot.tool, Tool.LASER)
})

test('hit', t => {
  const game = new Game()
  const robot = game.players[0].robots[0]
  t.is(game.hit(robot.location), 'destroy')
  t.true(robot.destroyed)
})

test('hitInLine hits robots in the line', t => {
  t.plan(20)
  const game = new Game()
  game.hitInLine(new Point(2, 2), 90)
  for (const player of game.players) {
    for (const robot of player.robots) {
      if (
        robot.location.equals(new Point(2, 17))
          || robot.location.equals(new Point(2, 18))
          || robot.location.equals(new Point(2, 19))
      ) {
        t.true(robot.destroyed)
      } else {
        t.false(robot.destroyed)
      }
    }
  }
  game.players[3]
})

test('hitInLine is stopped by shields', t => {
  t.plan(20)
  const game = new Game()
  const robot = game.robotAt(new Point(2, 18))
  if (robot) {
    robot.tool = Tool.SHIELD
  } else {
    t.fail()
  }
  game.hitInLine(new Point(2, 2), 90)
  for (const player of game.players) {
    for (const robot of player.robots) {
      if (robot.location.equals(new Point(2, 17))) {
        t.true(robot.destroyed)
      } else if (robot.location.equals(new Point(2, 18))) {
        t.is(robot.tool, null)
      } else {
        t.false(robot.destroyed)
      }
    }
  }
  game.players[3]
})
