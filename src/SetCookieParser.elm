module SetCookieParser exposing (Attribute(..), NameValue, SetCookie, attribute, nameValue, run)

import Char
import Parser
    exposing
        ( (|.)
        , (|=)
        , Parser
        , chompIf
        , chompWhile
        , getChompedString
        , int
        , oneOf
        , problem
        , spaces
        , succeed
        , symbol
        , variable
        )
import Set


type alias SetCookie =
    { name : String
    , value : String
    }



-- NAME-VALUE
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



-- ATTRIBUTES


type Attribute
    = Expires String



-- Loop until no ';' at the end
-- Ignore unrecognised attributes
-- Handle each attribute separately


attributes =
    identity


attribute : Parser Attribute
attribute =
    succeed identity
        |. symbol ";"
        |= name
        |> Parser.andThen
            (\an ->
                case String.toLower an of
                    "expires" ->
                        expires

                    -- TODO: Unknown: ignore the whole thing
                    _ ->
                        problem "I don't know how to parse that attribute yet..."
            )


expires : Parser Attribute
expires =
    succeed Expires
        |. spaces
        |. symbol "="
        |. spaces
        |= oneOrMore (\c -> notReserved c)
        -- NOTE: This bit does nothing atm, because we must parse the date to prevent dangling spaces
        |. spaces



-- GENERAL


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
