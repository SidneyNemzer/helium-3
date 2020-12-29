NOTES

# Animation

- Animations could be per robot. By default, they are independant. Settings scores affects the same state
  but that's fine if it's a delta. Sucking up H3 from the ground is more interesting, possibly a race condition?
  Some state can be determined when generating the animation steps, and the result is stored in the animation.

Turn phases are move, mine, shoot (avoids H3 dropping and affecting mining values)

- FireLaser, Kamikaze, and FireMissile have to take into account the server state. Maybe they should ignore the local state, like who should be destroyed? And there can be separate functions that the server uses which DO take into account local state.

```elm
fireMissile : RobotIndex -> Cell -> Bool -> Model -> Model
fireMissile shooter target targetHadShield model =

-- for server

fireMissile : RobotIndex -> Cell -> Bool -> Model -> (Model, ServerAction)
fireMissile shooter target targetHadShield model =
```

might be a lot of boilerplate if all actions have to reset the robot's tools? maybe actions should take as few arguments as possible in order to update the state they need. IE arming a missile only updates one robot. Shooting a missile updates the shooter and target. Mining updates the score, robot, and board.

# Alternate animation system

Store animations in msg

```elm
type Msg
  = Animation (List Animation)
```

Parallel animations can be independent

Blocking animations are just a big list

# Robot States

```elm
-- Current types

type Tool
    = Shield
    | Laser
    | Missile

type alias Robot =
    { id : Int
    , location : Cell
    , action : Maybe Action
    , tool : Maybe Tool
    }

-- invalid....
{
  action = Just FireLaser <direction>
  tool = Nothing
}

-- Alternative
{
  tool = Just FireLaser <direction>
}

type Tool
  = Shield
  | Laser
  | Missile

type Action
  -- On the next turn, the robot will move and maybe equip a new tool
  = Pending { pending : Maybe Tool, current : Maybe Tool, target : Cell }
  -- The robot won't do anything on the next turn, maybe it has a tool equiped.
  | Idle (Maybe Tool)
  -- The robot will self destruct on the next turn. If the robot's shield is active,
  -- the shield will prevent the robot from destroying itself.
  | SelfDestruct (Maybe Tool)
  -- The robot will fire a missile on its next turn
  | FireMissile Cell Bool
  -- The robot will fire a laser on its next turn
  | FireLaser Direction
  -- The robot was destroyed
  | Destroyed

-- A basic robot
{
  location = (1, 1)
}

-- Robot with a missile armed
{
  location = (1, 1)
  tool = Missile
}

-- Robot about to fire a missile
{
  location = (1, 1)
  tool = MissileAimedAt (1, 2)
}

-- Or
{
  location = (1, 1)
  target = Just (1, 1)
  tool = Just Missile
}

-- Just missile armed
{
  location = (1, 1)
  target = Nothing
  tool = Just Missile
}

type Tool -- State?
  = MissileAimedAt Cell
  | MissileArmed
  | LaserAimedAt Direction
  | WillArmMissile
  | WillArmLaser
  | WillArmShield
  | WillSelfDestruct
  | WillMine
  | WillMove

-- tool transitions
-- None -------------> Missile Armed --------------> None
--       Arm Missile                  Fire Missile


-- Above cannot represent "Missile Armed, will arm laser"
```

# Animation Steps For Move

1. Rotate to face target cell
2. Drive forward to target

# Animation Steps For Arm Missile

1. Rotate to face target cell
2. Missile enters (zoom + fade)
3. Drive forward to target

# Animation Steps For Fire Missile

1. Rotate to face target
2. Missile slides to target
3. Explosion appears on top of target (zoom + fade)
4. Without shield: Missile, explosion, and robot fade
   With shield: Missile, explosion, and becomes opaque
   Shield fades

```elm
type AnimationStep
  = RobotRotate
  -- Robot's location changes. Note that robot should be facing the
  -- direction it moves.
  | RobotDrive
  -- Missile zooms and fades
  | MissileAppear
  -- Missile moves from the robot that is firing to the target
  | MissileShoot
```
