module SetCookieParser exposing (NameValue, SetCookie, nameValue, run)

import Char
import Parser exposing ((|.), (|=), Parser, chompIf, chompWhile, getChompedString, int, spaces, succeed, symbol, variable)
import Set


type alias SetCookie =
    { name : String
    , value : String
    }



-- Each cookie begins with a name-value-pair, followed by zero or more attribute-value pairs.


type alias NameValue =
    { name : String
    , value : String
    }


nameValue : Parser NameValue
nameValue =
    succeed NameValue
        |= name
        |. symbol "="
        |= value


name : Parser String
name =
    succeed identity
        |= oneOrMore notReserved


value : Parser String
value =
    succeed identity
        |= oneOrMore notReserved


notReserved : Char -> Bool
notReserved =
    not << isEqualSign


isEqualSign : Char -> Bool
isEqualSign char =
    char == '='


run =
    Parser.run nameValue



-- UTIL


zeroOrMore : (Char -> Bool) -> Parser String
zeroOrMore isOk =
    succeed ()
        |. chompWhile isOk
        |> getChompedString


oneOrMore : (Char -> Bool) -> Parser String
oneOrMore isOk =
    succeed ()
        |. chompIf isOk
        |. chompWhile isOk
        |> getChompedString
