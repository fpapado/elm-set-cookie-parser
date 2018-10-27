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
            , test "=value"
                (\_ ->
                    let
                        input =
                            "=100"

                        expected =
                            { name = "", value = "100" }
                    in
                    Parser.run SetCookieParser.nameValue input
                        |> Expect.equal (Result.Ok expected)
                )
            , test "=value;"
                (\_ ->
                    let
                        input =
                            "=100;"

                        expected =
                            { name = "", value = "100" }
                    in
                    Parser.run SetCookieParser.nameValue input
                        |> Expect.equal (Result.Ok expected)
                )
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
            , test "="
                (\_ ->
                    let
                        input =
                            "="

                        expected =
                            { name = "", value = "" }
                    in
                    Parser.run SetCookieParser.nameValue input
                        |> Expect.equal (Result.Ok expected)
                )
            ]
        ]
