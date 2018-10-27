module SetCookieParser exposing (NameValue, SetCookie, nameValue, run)

import Char
import Parser exposing ((|.), (|=), Parser, chompIf, chompWhile, getChompedString, int, spaces, succeed, symbol, variable)
import Set


type alias SetCookie =
    { name : String
    , value : String
    }



-- Each cookie begins with a name-value-pair, followed by zero or more attribute-value pairs.
-- The (possibly empty) name string consists of the characters up
-- to, but not including, the first %x3D ("=") character, and the
-- (possibly empty) value string consists of the characters after
-- the first %x3D ("=") character.


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
        |. spaces
        |= oneOrMore (\c -> notReserved c && not (isSpace c))
        |. spaces


value : Parser String
value =
    succeed identity
        |. spaces
        |= zeroOrMore (\c -> notReserved c && not (isSpace c))
        |. spaces


notReserved : Char -> Bool
notReserved c =
    not (isEqualSign c)
        && not (isSemi c)


isSpace : Char -> Bool
isSpace c =
    c == ' ' || c == '\n' || c == '\u{000D}'


isEqualSign : Char -> Bool
isEqualSign char =
    char == '='


isSemi : Char -> Bool
isSemi char =
    char == ';'


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
