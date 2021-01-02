import { Point } from "./point";

const MAX_MINE_PER_SQUARE = 116;

/**
 * The Helium 3 Map tracks the amount of Helium 3. It is always 20x20 because
 * that's the size of the Helium 3 game board.
 *
 * When the class is constructed, Helium 3 is distributed onto the map
 */
export class Helium3Map {
  map: Map<Point, number>;

  constructor() {
    // TODO random generation
    this.map = new Map([[new Point(10, 10), 10]]);
  }

  minePoint = (point: Point): number => {
    const squareAmount = this.map.get(point) || 0;
    const mined = Math.min(MAX_MINE_PER_SQUARE, squareAmount);
    this.map.set(point, squareAmount - mined);
    return mined;
  };

  /**
   * Mines H3 around the given point, which removes H3 from the board and
   * returns the amount that was mined.
   * @param  point [description]
   * @return       [description]
   */
  mine = (point: Point): number => {
    return point.around(true).reduce((minedTotal: number, point: Point) => {
      return minedTotal + this.minePoint(point);
    }, 0);
  };

  add = (point: Point, amount: number) => {
    this.map.set(point, (this.map.get(point) || 0) + amount);
  };

  /**
   * Distributes H3 onto the map, for example after a robot is destroyed
   */
  drop = (point: Point, amount: number): void => {
    point
      .around(true)
      .filter((point) => point.within(20, 20))
      .forEach((point, _, { length }) => this.add(point, amount / length));
  };

  toJSON = () => {
    return Array.from(this.map).map(([point, amount]) => [
      point.toJSON(),
      amount,
    ]);
  };
}
