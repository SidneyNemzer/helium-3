# Helium 3

### Table of Contents

- [Matches](#matches)
- [X-TRACT Robots](#x-tract-robots)
  - [Mining](#mining)
  - [Shield](#shield)

## Matches

Four players compete in a ten minute battle. The battle takes place on the moon in a 20x20 grid. Players take turns moving two of their five robots to mine Helium 3 or attack other robots. The winner is the player with the most money and at least one X-TRACT robot at the end of the game.

\$40,000 of Helium 3 is randomly distributed over the moon's surface before the game starts. Helium 3 tends to concentrate in clumps.

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

### Mining

X-TRACT robots can mine Helium 3 from the moon's surface. Mining a square removes up to $500 of Helium 3 from the square under the robot and $250 of Helium 3 from each neighboring square.

### Shield

Players can only see shields on their own robots.

Robots with an active shield are immune to all damage, but taking any damage or performing any action disarms the shield. Hitting a shielded robot with a laser stops the laser.

Shields can also be used to deflect lasers; when shielding a robot, the player can optionally choose a direction to deflect lasers. Any lasers hitting the shield deflect in the chosen direction. Just like firing a laser, deflection happens at 45 degree angles (including back at the source of the laser). A laser can be deflected by multiple times by different robots.

### Animation

Turn length can vary depending on the actions that the robots perform. However in general, animation time is constant to reduce the complexity of calculating the animation time.

Rotation must be constant or not factored in (maybe part of padding?) because the server will not track rotation. Eg,
if a robot needs to rotate vs is already facing its target, the animation time cannot change.

Move time also remains constant regardless of the distance. This helps keep turn length from varying significatly depending on move distance.

Other than that, turn length varies based on the actions performed. Of course, turn length is the longer animation time of the robots that are moving. (Robots may not finish at the same time even in the same turn).

Turns may have a minimum time and some padding to prevent turns with zero second actions from being instant.

Actions presented to the user are: Move, ArmMissile, ArmLaser, Shield, Mine, Kamikaze, FireMissile, FireLaser

Actions are broken into the following descrete animations:

TODO pause between some animations

- Move
  - move
- ArmMissile
  - extend weapon
  - rotate\*
  - move\*
  - extend stabalizers
- ArmLaser
  - extend weapon
  - rotate\*
  - move\*
  - extend stabalizers
- Shield
  - move\*
  - project shield
- Mine
  - move\*
  - extend vacuum
  - retract vacuum
- Kamikaze
  - bomb jumps above robot
  - explodes / highlight shield of adjacent robots
- FireMissile
  - rotate\*
  - missile flies
  - explods target / highlight shield
- FireLaser
  - rotate\*
  - laser travels

Animations details:

- move: robot slides from one tile to another (ease-in-out 1s)
  - time is constant regardless of distance
  - does not occur when robot is already on target tile
- rotate: robot turns to face target (linear, 0.5s)
  - time is constant regardless of angle
  - does not occur when robot is already facing the target
- extend weapon: laser or missile extends from the body of the robot (0.5s)
  - does not occur if weapon was already armed (robot was moved with armed weapon)?
    - maybe weapon should retract and extend to keep time constant
- extend stabalizers: small legs extend from the robot body (0.5s)
  - might occur in padding so does not affect turn length?
- project shield: a light, transparent sphere appears around the robot (0s)
- bomb jumps above robot (0.5s)
  - this draws attention to the robot
- explodes: robot vaporizes with some particle effects (0.5s)
  - also drops helium 3 back onto the game space
- highlight shield: shield becomes more opaque before fading (1s)
  - visually shows that the shield prevented damage
- missile files: missile arcs above the board then twoard the target (0.5s)
  - missile leaves particle trail
- laser travels
  - TODO (this is complicated to predict the time of since it's potentially recursive!)
