module SetCookieParser exposing (Attribute(..), NameValue, SetCookie, attribute, attributes, nameValue, run)

import Char
import Parser
    exposing
        ( (|.)
        , (|=)
        , Parser
        , Trailing(..)
        , chompIf
        , chompWhile
        , getChompedString
        , int
        , loop
        , oneOf
        , problem
        , sequence
        , spaces
        , succeed
        , symbol
        , variable
        )
import Set


type alias SetCookie =
    { name : String
    , value : String

    -- , attributes : List Attribute
    }


setCookie : Parser SetCookie
setCookie =
    succeed identity
        |= nameValue



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
-- NOTE: Technically, both Expires and Max-Age are an expiry-time.
-- Takes into account the current time +/- the Max-Age for Max-Age.
-- This seems more a responsibility of the UA/application than the parser :)
-- @see: https://tools.ietf.org/html/rfc6265#section-5.2.2


type Attribute
    = Expires String
    | MaxAge Int
    | Domain String
    | Path String
    | Secure
    | HttpOnly



-- Loop until no ';' at the end
-- Ignore unrecognised attributes
-- Handle each attribute separately
-- TODO: Loop, looking for attributes


attributes : Parser (List Attribute)
attributes =
    sequence
        { start = ""
        , end = ""
        , separator = ";"
        , spaces = spaces
        , item = attribute
        , trailing = Forbidden
        }


attribute : Parser Attribute
attribute =
    succeed identity
        |= name
        |> Parser.andThen
            (\an ->
                case String.toLower an of
                    "expires" ->
                        expires

                    "max-age" ->
                        maxAge

                    "domain" ->
                        domain

                    "path" ->
                        path

                    "secure" ->
                        secure

                    "httponly" ->
                        httpOnly

                    -- TODO: Unknown: ignore the whole thing
                    _ ->
                        problem "I don't know how to parse that attribute yet..."
            )
        -- NOTE: This bit does nothing for "Expires", because we must parse the date to prevent dangling spaces
        -- TODO: Consider whether this is the best place to handle these spaces
        |> Parser.andThen (\a -> succeed a |. spaces)



-- EXPIRES


expires : Parser Attribute
expires =
    succeed Expires
        |. spaces
        |. symbol "="
        |. spaces
        |= oneOrMore (\c -> notReserved c)



-- MAX-AGE


maxAge : Parser Attribute
maxAge =
    succeed MaxAge
        |. spaces
        |. symbol "="
        |. spaces
        |= oneOf
            [ int

            -- TODO: If not an int, we should ignore and chomp until the end.
            -- How do we represent that? With a Maybe? Or something else?
            , problem "I was expecting a DIGIT. Ignoring the attribute-value when the value is not a digit has not yet been implemented."
            ]



-- DOMAIN


domain : Parser Attribute
domain =
    succeed Domain
        |. spaces
        |. symbol "="
        |. spaces
        |= oneOrMore (\c -> notReserved c)
        |> Parser.map (mapDomain normaliseCookieDomain)



-- If the first character of the attribute-value string is %x2E ("."):
--  Let cookie-domain be the attribute-value without the leading %x2E
--  (".") character.
-- Otherwise:
--   Let cookie-domain be the entire attribute-value
-- Convert the cookie-domain to lower case.


normaliseCookieDomain : String -> String
normaliseCookieDomain str =
    (case String.left 1 str of
        "." ->
            String.dropLeft 1 str

        _ ->
            str
    )
        |> String.toLower


mapDomain fn attr =
    case attr of
        Domain str ->
            Domain (fn str)

        _ ->
            attr



-- PATH


path : Parser Attribute
path =
    succeed Path
        |. spaces
        |. symbol "="
        |. spaces
        -- TODO: Check that "" is given if it is empty
        |= oneOrMore (\c -> notReserved c)



-- SECURE


secure : Parser Attribute
secure =
    succeed Secure



-- HttpOnly


httpOnly : Parser Attribute
httpOnly =
    succeed HttpOnly



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


ignoreToSemi =
    succeed ()
        |. oneOrMore (not << isSemi)



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
