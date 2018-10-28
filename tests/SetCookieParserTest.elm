module SetCookieParserTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Parser
import Result
import SetCookieParser
import Test exposing (..)


suite : Test
suite =
    describe "Set-Cookie Parser"
        [ describe "name-value"
            [ test "Parses a string-string name-value pair"
                (\_ ->
                    let
                        input =
                            "me=fotis"

                        expected =
                            { name = "me", value = "fotis" }
                    in
                    Parser.run SetCookieParser.nameValue input
                        |> Expect.equal (Result.Ok expected)
                )
            , test "Parsers a string-number name-value pair"
                (\_ ->
                    let
                        input =
                            "count=100"

                        expected =
                            { name = "count", value = "100" }
                    in
                    Parser.run SetCookieParser.nameValue input
                        |> Expect.equal (Result.Ok expected)
                )
            , test "Fails if = is not present"
                (\_ ->
                    let
                        input =
                            "count 100"
                    in
                    Parser.run SetCookieParser.nameValue input
                        |> isErr
                        |> Expect.true "Expected the header parse to be rejected"
                )
            , test "name=value;"
                (\_ ->
                    let
                        input =
                            "count=100;"

                        expected =
                            { name = "count", value = "100" }
                    in
                    Parser.run SetCookieParser.nameValue input
                        |> Expect.equal (Result.Ok expected)
                )
            , describe "If the name string is empty, ignore the set-cookie-string entirely."
                [ test "Rejects =value"
                    (\_ ->
                        let
                            input =
                                "=100"

                            expected =
                                { name = "", value = "100" }
                        in
                        Parser.run SetCookieParser.nameValue input
                            |> isErr
                            |> Expect.true "Expected the parse to be rejected"
                    )
                , test "Rejects =value;"
                    (\_ ->
                        let
                            input =
                                "=100;"

                            expected =
                                { name = "", value = "100" }
                        in
                        Parser.run SetCookieParser.nameValue input
                            |> isErr
                            |> Expect.true "Expected the parse to be rejected"
                    )
                , test "Rejects ="
                    (\_ ->
                        let
                            input =
                                "="

                            expected =
                                { name = "", value = "" }
                        in
                        Parser.run SetCookieParser.nameValue input
                            |> isErr
                            |> Expect.true "Expected the parse to be rejected"
                    )
                ]
            , test "name=;"
                (\_ ->
                    let
                        input =
                            "count="

                        expected =
                            { name = "count", value = "" }
                    in
                    Parser.run SetCookieParser.nameValue input
                        |> Expect.equal (Result.Ok expected)
                )
            , test "Removes any leading or trailing WSP characters from the name string and the value string."
                (\_ ->
                    let
                        input =
                            "  count  =  100  "

                        expected =
                            { name = "count", value = "100" }
                    in
                    Parser.run SetCookieParser.nameValue input
                        |> Expect.equal (Result.Ok expected)
                )
            ]
        , describe "cookie-av (Attributes)"
            [ -- [ describe "If the cookie-av string contains a = character"
              --     [ describe "The (possibly empty) attribute-name string consists of the characters up to, but not including, the first = character, and the (possibly empty) attribute-value string consists of the characters after the first = character."
              --         [ test "; Max-Age=615"
              --         ]
              --     ]
              -- , describe "If the cookie-av string does not contain a = character"
              --     [ describe "The attribute-name string consists of the entire cookie-av string, and the attribute-value string is empty."
              --         [ test "; HttpOnly"
              --         ]
              --     ]
              -- ]
              -- , describe "Remove any leading or trailing WSP characters from the attribute-name string and the attribute-value string."
              --     [ test ";   Max-Age = 615  " ]
              -- , describe "Attributes with unrecognized attribute-names are ignored"
              --     [ test "; UnrecognisedAttribute=615"
              --     ]
              describe "The Expires Attribute"
                [ test "Parses Expires=Monday, June 28, 2018"
                    (\_ ->
                        let
                            input =
                                "Expires=Monday, June 28, 2018"

                            expected =
                                SetCookieParser.Expires "Monday, June 28, 2018"
                        in
                        Parser.run SetCookieParser.attribute input
                            |> Expect.equal (Result.Ok expected)
                    )
                , test "Parses expires=Monday, June 28, 2018"
                    (\_ ->
                        let
                            input =
                                "expires=Monday, June 28, 2018"

                            expected =
                                SetCookieParser.Expires "Monday, June 28, 2018"
                        in
                        Parser.run SetCookieParser.attribute input
                            |> Expect.equal (Result.Ok expected)
                    )
                , test "Parses Expires  =  Monday, June 28, 2018"
                    (\_ ->
                        let
                            input =
                                "expires  =  Monday, June 28, 2018"

                            expected =
                                SetCookieParser.Expires "Monday, June 28, 2018"
                        in
                        Parser.run SetCookieParser.attribute input
                            |> Expect.equal (Result.Ok expected)
                    )
                , todo "Parses Expires=31688000  without trailing space. This probably needs us to parse the date, so that we can skip the extra bits."
                , todo "Ignores invalid date"
                ]

            -- , describe "The Max-Age Attribute"
            --     [ test "Parses ; Max-Age=DIGIT"
            --     , test "Parses ; max-age=DIGIT"
            --     -- That means Nothing
            --     , test "Ignores non-DIGIT value"
            --     , test "Ignores invalid date"
            --     ]
            -- , describe "The Domain Attribute" []
            -- , describe "The Path Attribute" []
            , describe "The Secure Attribute"
                [ test "Parses Secure"
                    (\_ ->
                        let
                            input =
                                "Secure"

                            expected =
                                SetCookieParser.Secure
                        in
                        Parser.run SetCookieParser.attribute input
                            |> Expect.equal (Result.Ok expected)
                    )
                ]

            -- , describe "The HttpOnly Attribute" []
            ]
        , describe "Multiple attributes"
            [ test "Parses Max-Age=12345; HttpOnly"
                (\_ ->
                    let
                        input =
                            "Max-Age=12345; HttpOnly"

                        expected =
                            [ SetCookieParser.MaxAge 12345, SetCookieParser.HttpOnly ]
                    in
                    Parser.run SetCookieParser.attributes input
                        |> Expect.equal (Result.Ok expected)
                )
            ]
        , describe "Set-Cookie parsing"
            [ test "Parses count=300; Max-Age=12345; HttpOnly"
                (\_ ->
                    let
                        input =
                            "count=300; Max-Age=12345; HttpOnly"

                        expected =
                            { name = "count"
                            , value = "300"
                            , attributes =
                                [ SetCookieParser.MaxAge 12345, SetCookieParser.HttpOnly ]
                            }
                    in
                    SetCookieParser.fromString input
                        |> Expect.equal (Result.Ok expected)
                )
            ]
        , describe "toString"
            [ test "Serialises count=300; Max-Age=12345; HttpOnly"
                -- NOTE/TODO: The order shouldn't matter here...
                (\_ ->
                    let
                        input =
                            { name = "count"
                            , value = "300"
                            , attributes =
                                [ SetCookieParser.MaxAge 12345, SetCookieParser.HttpOnly ]
                            }

                        expected =
                            "count=300; HttpOnly; Max-Age=12345"
                    in
                    SetCookieParser.toString input
                        |> Expect.equal expected
                )
            ]
        ]



-- UTIL


isErr : Result error data -> Bool
isErr res =
    case res of
        Ok _ ->
            False

        Err _ ->
            True
