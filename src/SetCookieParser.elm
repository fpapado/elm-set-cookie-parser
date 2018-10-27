module SetCookieParser exposing (Point, point)

import Parser exposing ((|.), (|=), Parser, int, spaces, succeed, symbol)


type alias Point =
    { x : Int, y : Int }


point : Parser Point
point =
    succeed Point
        |. symbol "("
        |. spaces
        |= int
        |. symbol ","
        |. spaces
        |= int
        |. spaces
        |. symbol ")"
