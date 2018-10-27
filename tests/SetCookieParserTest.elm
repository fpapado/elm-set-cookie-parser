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
        ]



-- UTIL


isErr : Result error data -> Bool
isErr res =
    case res of
        Ok _ ->
            False

        Err _ ->
            True
