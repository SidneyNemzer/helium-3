module Missile exposing (def, view)

import Point exposing (Point)
import Svg
    exposing
        ( Svg
        , defs
        , ellipse
        , feBlend
        , feColorMatrix
        , feComposite
        , feFlood
        , feGaussianBlur
        , feOffset
        , g
        , rect
        , svg
        , use
        )
import Svg.Attributes as SA exposing (..)


view : Point -> Float -> Svg msg
view location rotation =
    let
        ( x, y ) =
            Point.topLeft location
    in
    Svg.use
        [ SA.x (String.fromInt (x - 20))
        , SA.y (String.fromInt (y - 20))
        , width (String.fromInt (Point.cellSide + 40))
        , height (String.fromInt (Point.cellSide + 40))
        , transform <|
            "rotate("
                ++ String.fromFloat rotation
                ++ ", "
                ++ String.fromInt (x + Point.cellSide // 2)
                ++ ", "
                ++ String.fromInt (y + Point.cellSide // 2)
                ++ ")"
        , xlinkHref "#missile"
        ]
        []


def : Svg msg
def =
    svg [ width "55", height "21", viewBox "0 0 55 21", fill "none", id "missile" ]
        [ g [ filter "url(#filter0_i)" ]
            [ Svg.path [ d "M3 0H6L12 8H3L3 0Z", fill "#F06262" ] []
            , Svg.path [ d "M3 21H6L12 13H3L3 21Z", fill "#F06262" ] []
            , ellipse [ cx "28.6701", cy "10.5001", rx "26.3299", ry "4.49987", fill "white" ] []
            , Svg.mask [ id "mask0", maskUnits "userSpaceOnUse", x "42", y "5", width "13", height "11" ]
                [ rect [ x "42.3608", y "5", width "12.6383", height "10.9997", fill "#C4C4C4" ] [] ]
            , g [ mask "url(#mask0)" ]
                [ ellipse [ cx "28.6701", cy "10.5001", rx "26.3299", ry "4.49987", fill "#F16262" ] []
                ]
            , Svg.mask [ id "mask1", maskUnits "userSpaceOnUse", x "2", y "5", width "13", height "12" ]
                [ rect [ x "14.9788", y "16", width "12.6383", height "10.9997", transform "rotate(-180 14.9788 16)", fill "#C4C4C4" ] [] ]
            , g [ mask "url(#mask1)" ]
                [ ellipse [ cx "28.6704", cy "10.5001", rx "26.3299", ry "4.49987", transform "rotate(-180 28.6704 10.5001)", fill "#F16262" ] [] ]
            , Svg.mask [ id "mask2", maskUnits "userSpaceOnUse", x "-1", y "6", width "11", height "9" ]
                [ rect [ width "9.36174", height "7.11756", rx "3", transform "matrix(-1 0 0 1 9.36169 6.94128)", fill "#C4C4C4" ] [] ]
            , g [ mask "url(#mask2)" ]
                [ rect [ x "2.34045", y "7.58838", width "8.19152", height "5.82346", fill "#F06262" ] [] ]
            ]
        , defs []
            [ Svg.filter
                [ id "filter0_i"
                , x "0"
                , y "0"
                , width "55"
                , height "23"
                , filterUnits "userSpaceOnUse"
                , colorInterpolationFilters "sRGB"
                ]
                [ feFlood [ floodOpacity "0", result "BackgroundImageFix" ] []
                , feBlend [ mode "normal", in_ "SourceGraphic", in2 "BackgroundImageFix", result "shape" ] []
                , feColorMatrix [ in_ "SourceAlpha", values "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0", result "hardAlpha" ] []
                , feOffset [ dy "2" ] []
                , feGaussianBlur [ stdDeviation "1" ] []
                , feComposite [ in2 "hardAlpha", operator "arithmetic", k2 "-1", k3 "1" ] []
                , feColorMatrix [ values "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0" ] []
                , feBlend [ mode "normal", in2 "shape", result "effect1_innerShadow" ] []
                ]
            ]
        ]



-- <svg width="55" height="21" viewBox="0 0 55 21" fill="none" xmlns="http://www.w3.org/2000/svg">
-- <g filter="url(#filter0_i)">
-- <path d="M3 0H6L12 8H3L3 0Z" fill="#F06262"/>
-- <path d="M3 21H6L12 13H3L3 21Z" fill="#F06262"/>
-- <ellipse cx="28.6701" cy="10.5001" rx="26.3299" ry="4.49987" fill="white"/>
-- <mask id="mask0" mask-type="alpha" maskUnits="userSpaceOnUse" x="42" y="5" width="13" height="11">
-- <rect x="42.3608" y="5" width="12.6383" height="10.9997" fill="#C4C4C4"/>
-- </mask>
-- <g mask="url(#mask0)">
-- <ellipse cx="28.6701" cy="10.5001" rx="26.3299" ry="4.49987" fill="#F16262"/>
-- </g>
-- <mask id="mask1" mask-type="alpha" maskUnits="userSpaceOnUse" x="2" y="5" width="13" height="12">
-- <rect x="14.9788" y="16" width="12.6383" height="10.9997" transform="rotate(-180 14.9788 16)" fill="#C4C4C4"/>
-- </mask>
-- <g mask="url(#mask1)">
-- <ellipse cx="28.6704" cy="10.5001" rx="26.3299" ry="4.49987" transform="rotate(-180 28.6704 10.5001)" fill="#F16262"/>
-- </g>
-- <mask id="mask2" mask-type="alpha" maskUnits="userSpaceOnUse" x="-1" y="6" width="11" height="9">
-- <rect width="9.36174" height="7.11756" rx="3" transform="matrix(-1 0 0 1 9.36169 6.94128)" fill="#C4C4C4"/>
-- </mask>
-- <g mask="url(#mask2)">
-- <rect x="2.34045" y="7.58838" width="8.19152" height="5.82346" fill="#F06262"/>
-- </g>
-- </g>
-- <defs>
-- <filter id="filter0_i" x="0" y="0" width="55" height="23" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
-- <feFlood flood-opacity="0" result="BackgroundImageFix"/>
-- <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/>
-- <feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>
-- <feOffset dy="2"/>
-- <feGaussianBlur stdDeviation="1"/>
-- <feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/>
-- <feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/>
-- <feBlend mode="normal" in2="shape" result="effect1_innerShadow"/>
-- </filter>
-- </defs>
-- </svg>
