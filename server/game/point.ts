export class Point {
  readonly x: number
  readonly y: number
  constructor(x: number, y: number) {
    this.x = x
    this.y = y
  }

  translate(tx: number, ty: number): Point {
    return new Point(
      this.x + tx,
      this.y + ty
    )
  }

  /**
   * Returns an array of the points around this point
   * @param  includeCenter When true, the center point is included in the returned array
   */
  around(includeCenter: boolean): Point[] {
    return [
      this.translate(-1, -1),
      this.translate(-1, 0),
      this.translate(-1, 1),
      this.translate(0, -1),
      this.translate(0, 1),
      this.translate(-1, -1),
      this.translate(-1, 0),
      this.translate(-1, 1)
    ].concat(includeCenter ? [ this ] : [])
  }

  within(width: number, height: number) {
    return this.x >= 0 && this.y >= 0 && this.x < width && this.y < height
  }
}
