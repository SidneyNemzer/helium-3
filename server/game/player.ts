import { Point } from "./point";
import { Robot } from "./robot";
import { Game, PlayerIndex } from "./game";
import { RobotStartPositions } from "./robot-start-positions";

export class Player {
  game: Game;
  robots: Robot[];
  helium3: number;

  constructor(game: Game, playerIndex: PlayerIndex) {
    this.game = game;
    this.robots = RobotStartPositions[playerIndex].map(
      ([x, y]) => new Robot(game, this, new Point(x, y))
    );
    this.helium3 = 0;
  }

  move = () => {
    return this.robots.map((robot) => robot.move());
  };

  toJSON = () => {
    return {
      robots: this.robots.map((robot) => robot.toJSON()),
      helium3: this.helium3,
    };
  };
}
