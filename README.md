# elm-set-cookie-parser

> A parser for the Set-Cookie header, written in Elm.

:construction: Not yet published :construction:

## Usage

```elm
import SetCookieParser exposing (SetCookie)

headerString = "count=300; Max-Age=12345; HttpOnly"

header : Result err SetCookie
header = SetCookieParser.fromString headerString
```

## Why? Why not?

Mostly not.

There is probably no reason to want to parse this header on the client-side of a web app, since the browser does that already.
Similarly, on the server, there is more behaviour tied to Cookies, so your server most likely handles parsing already.
You also probably don't want to store the cookies in scripts in the first place.

On my part, I just felt like trying out the Elm Parser API, because it looked fun! And the Set-Cookie header was giving me pain recently, so it was a good chance to demistify it.

If you ever do want to parse or understand the Set-Cookie header, I hope this can be a lightweight, readable version :)

## Development

Install the Elm dependencies:

```sh
npm install
```

Run the test suite:

```sh
elm-test
```

## Limitations

Here are some things I did not attempt currently.
Feel free to open an Issue to discuss before trying them out and sending a PR!

- Only parses single headers at the moment. You would have to manually split a string that contains multiple headers.

- Does not attempt to parse the date in the "Expires" header at the moment.

## References

- [The Set-Cookie header is part of RFC 6265](https://tools.ietf.org/html/rfc6265)
