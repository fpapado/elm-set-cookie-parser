module SetCookieParser exposing
    ( Attribute(..)
    , NameValue
    , SetCookie
    , attribute
    , attributes
    , fromString
    , nameValue
    , parser
    , toString
    )

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
        , oneOf
        , problem
        , sequence
        , spaces
        , succeed
        , symbol
        )
import Set


type alias SetCookie =
    { name : String
    , value : String
    , attributes : List Attribute
    }


{-| Attempt to convert a String representation of a Set-Cookie Header to a SetCookie
-}
fromString : String -> Result (List Parser.DeadEnd) SetCookie
fromString =
    Parser.run parser



-- Attempt to convert a string representation of a series of Set-Cookie Headers to a list of SetCookie
-- NOTE: If the Set-Cookie Header strings are already separate, it is recommended that you use fromString multiple times instead.
-- TODO: Decide whether it should be Result x (List SetCookie) or List (Result x SetCookie)
-- fromMultiString : String -> Result (List Parser.DeadEnd) (List SetCookie)
-- fromMultiString =
-- Debug.todo "Not yet implemented"


{-| Serialise a SetCookie to a Set-Cookie Header string
-}
toString : SetCookie -> String
toString sc =
    let
        cookieNameValue =
            formatNameValue sc.name sc.value

        cookieAttributes =
            List.map attributeToString sc.attributes
                |> joinPrepend "; "
    in
    cookieNameValue ++ cookieAttributes


formatNameValue a b =
    a ++ "=" ++ b


attributeToString attr =
    case attr of
        Expires str ->
            formatNameValue "Expires" str

        MaxAge int ->
            formatNameValue "Max-Age" (String.fromInt int)

        Domain str ->
            formatNameValue "Domain" str

        Path str ->
            formatNameValue "Path" str

        Secure ->
            "Secure"

        HttpOnly ->
            "HttpOnly"



-- PARSER INTERNALS


parser : Parser SetCookie
parser =
    succeed SetCookie
        |= name
        |. symbol "="
        |= value
        -- TODO: Move first ";" to the attributes parser, per the spec
        |. symbol ";"
        |= attributes



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


attributes : Parser (List Attribute)
attributes =
    sequence
        { start = ""
        , end = ""
        , separator = ";"
        , spaces = spaces
        , item = attribute

        -- TODO: Decide what trailing actually does
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


joinPrepend : String -> List String -> String
joinPrepend separator strings =
    List.foldl (\a b -> separator ++ a ++ b) "" strings
