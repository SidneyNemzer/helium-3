module Svg.Arrow exposing (def, view)

import Color
import Game.Cell as Cell exposing (Cell, Direction)
import Game.Constants as Constants
import Svg
    exposing
        ( Svg
        , defs
        , line
        , marker
        , path
        , svg
        )
import Svg.Attributes exposing (..)


view : Cell -> Direction -> Svg msg
view robot direction =
    let
        arrowCell =
            Cell.move direction robot

        ( vX, vY ) =
            Cell.directionToXY direction

        halfCell =
            Constants.cellSide // 2

        quarterCell =
            halfCell // 2

        ( startX, startY ) =
            Cell.toScreenOffset2
                arrowCell
                Constants.cellSide
                ( halfCell - vX * quarterCell, halfCell - vY * quarterCell )

        ( endX, endY ) =
            Cell.toScreenOffset2 arrowCell
                Constants.cellSide
                ( halfCell + vX * (quarterCell - 10)
                , halfCell + vY * (quarterCell - 10)
                )
    in
    line
        [ x1 (String.fromInt startX)
        , y1 (String.fromInt startY)
        , x2 (String.fromInt endX)
        , y2 (String.fromInt endY)
        , markerEnd "url(#head)"
        , strokeWidth "10"
        , fill "none"
        , stroke Color.blue
        ]
        []


def : Svg msg
def =
    marker
        [ id "head"
        , orient "auto"
        , markerWidth "2"
        , markerHeight "4"
        , refX "0.1"
        , refY "2"
        ]
        [ Svg.path [ d "M0,0 V4 L2,2 Z", fill Color.blue ] [] ]
