# Helium 3

### Table of Contents

- [Matches](#matches)
- [X-TRACT Robots](#x-tract-robots)
  - [Mining](#mining)
  - [Shield](#shield)

## Matches

Four players compete in a ten minute battle. The battle takes place on the moon in a 20x20 grid. Players take turns moving two of their five robots to mine Helium 3 or attack other robots. The winner is the player with the most money and at least one X-TRACT robot at the end of the game.

Helium 3 is randomly distributed over the moon's surface before the game starts. Helium 3 tends to concentrate in clumps.

The match starts with a player in each corner of the map with their X-TRACT Robots in an "L" shape:

```
1 x        x 2
  x        x
xxx        xxx




xxx        xxx
  x        x
4 x        x 3
```

Not to scale. X = X-TRACT Robot. number = player number.

## Helium Distribution

Helium is distributed in randomly placed "large" and "small" deposits. There are randomly between two and three large deposits, and between three and five small deposits. If deposits overlap, cells are added together.

The center of a deposit must be at least five cells away from each spawn, and it must be on the board. This encourages robots to move before mining. Otherwise, the location of each deposit is random. Any helium off the edge of the map is inaccessible.

Large deposits are 5x5, with 1200 in the center, 750 in each cell in the 9x9 around the center, and 350 in each cell in the outer 5x5 ring. Small deposits are 3x3 with 750 in the center and 350 in the outer 3x3 ring.

## X-TRACT Robots

Each player starts with five X-TRACT robots. Players may move up to two robots on their turn.

Robots start in the "inactive" state, in which they are immune to damage. After a robot performs any action, it enters the "active" state, and can be destroyed. This keeps inactive robots safe until they are in play. When a robot is destroyed, 50% of the Helium 3 that the robot mined is dropped onto the surface, with most of it settling on the robots current square and some in neighboring cells.

An X-TRACT robot can preform one of the following actions per turn:

| Action       | Move Range | Notes                                                       |
| ------------ | ---------- | ----------------------------------------------------------- |
| Arm Missile  | 2          | Any other action disarms the missile.                       |
| Arm Laser    | 2          | Any other action disarms the laser.                         |
| Fire Missile | 0          | Range of missile: 6. Destroys robots that are directly hit. |
| Fire Laser   | 0          | Destroys all robots in a line. Fires on a 45 degree angle.  |
| Kamikaze     | 0          | Destroys self and robots in neighboring squares.            |
| Shield       | 5          | See [Shield](#shield).                                      |
| Mine         | 4          | See [Mining](#mining).                                      |
| Move         | 6          |                                                             |

"Move" obviously allows X-TRACT robots to move around the map. Some other actions allow the robots to move, but not as far as a dedicated move.

When a robot is destroyed, it drops half of the helium it mined (and the player loses that amount). Helium is dropped in a 3x3 area, with more in the center. The distribution uses a ratio of 350 to 750, matching the ratio of a generated small deposit. The forumla is:

```
x = amount in outer 3x3
y = amount in center

8x + y = amount dropped

x / y = 350 / 750
```

For example, if 5000 helium needs to be dropped, 1056 would land in the center and 493 would land in the 3x3 ring. Values are rounded down.

### Mining

X-TRACT robots can mine Helium 3 from the moon's surface. Mining a square removes up to $500 of Helium 3 from the square under the robot and $250 of Helium 3 from each neighboring square.

### Shield

Players can only see shields on their own robots.

Robots with an active shield are immune to all damage, but taking any damage or performing any action disarms the shield. Hitting a shielded robot with a laser stops the laser.

Shields can also be used to deflect lasers; when shielding a robot, the player can optionally choose a direction to deflect lasers. Any lasers hitting the shield deflect in the chosen direction. Just like firing a laser, deflection happens at 45 degree angles (including back at the source of the laser). A laser can be deflected by multiple times by different robots.

### Animation

Turn length can vary depending on the actions that the robots perform. Each action is made up of many small animations, but animations may be skipped in some situations. For example, robots must turn to face the direction they will move; however if the robot is already facing the correct direction, the turn animation is skipped.

> In the reference implementation, the animation code is shared between the client and server so that the server knows how long to wait a turn to animate.
