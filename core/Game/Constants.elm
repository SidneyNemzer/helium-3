module Game.Constants exposing
    ( gridSide
    , helium3InLargeDeposit
    , helium3InLargeDepositInnerRing
    , helium3InLargeDepositOuterRing
    , helium3LargeDepositCenter
    , helium3SmallDepositCenter
    , helium3SmallDepositOuterRing
    , maxMinedHelium3
    , secondsBeforeStart
    , secondsGameTime
    , secondsTurnCountdown
    , startingHelium3
    )


secondsBeforeStart : Int
secondsBeforeStart =
    5


secondsTurnCountdown : Int
secondsTurnCountdown =
    5


secondsGameTime : Int
secondsGameTime =
    60 * 10


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


gridSide : Int
gridSide =
    20
