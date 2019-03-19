module Game.Constants exposing
    ( cellSide
    , gridSide
    , helium3InLargeDeposit
    , helium3InLargeDepositInnerRing
    , helium3InLargeDepositOuterRing
    , helium3LargeDepositCenter
    , helium3SmallDepositCenter
    , helium3SmallDepositOuterRing
    , maxMinedHelium3
    , missileRange
    , moveAndArmWeaponRange
    , moveAndMineRange
    , moveAndShieldRange
    , moveRange
    , secondsBeforeStart
    , secondsGameTime
    , secondsTurnCountdown
    , startingHelium3
    )

-- TIME


secondsBeforeStart : Int
secondsBeforeStart =
    5


secondsTurnCountdown : Int
secondsTurnCountdown =
    5


secondsGameTime : Int
secondsGameTime =
    60 * 10



-- HELIUM 3 GENERATION AND MINING


maxMinedHelium3 : Int
maxMinedHelium3 =
    100


startingHelium3 : Float
startingHelium3 =
    40000


helium3InLargeDeposit : Float
helium3InLargeDeposit =
    startingHelium3 * 0.2


helium3LargeDepositCenter : Float
helium3LargeDepositCenter =
    0.8


helium3InLargeDepositInnerRing : Float
helium3InLargeDepositInnerRing =
    0.0575


helium3InLargeDepositOuterRing : Float
helium3InLargeDepositOuterRing =
    0.02875


helium3SmallDepositCenter : Float
helium3SmallDepositCenter =
    15


helium3SmallDepositOuterRing : Float
helium3SmallDepositOuterRing =
    0.10625



-- SIZE


gridSide : Int
gridSide =
    20


cellSide : Int
cellSide =
    100



-- ROBOTS
-- The radius of the area robots can move and shoot in


moveRange : Int
moveRange =
    4


moveAndShieldRange : Int
moveAndShieldRange =
    3


moveAndArmWeaponRange : Int
moveAndArmWeaponRange =
    2


missileRange : Int
missileRange =
    5


moveAndMineRange : Int
moveAndMineRange =
    3
