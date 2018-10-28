# TODO

## A collection of random thoughts and TODOs.

- Move first ";" to the attributes parser, per the spec

- If an Attribute is unknown, ignore and chomp until the next ';'

- Check that the Path's value is "" if empty

- If the Max-Age's value is not an int, we should ignore and chomp until the end.

- Perhaps do not expose the internal parser functions any more, test only full parses. Should the top-most parser be exposed, though?

  - Brings up the question whether this is a "Set-Cookie parser" or "Set-Cookie serialization/deserialization".
  - I like the idea of being able to compose the parsers, but does that not expose otherwise implementation details? Or are those details the things that matter?

- Parse the "Expected" attribute's date.

  - That'll be a pain. I question if it is even needed atm. It would help with dangling whitespace after the date though...
  - What would we parse to? Posix time per the core package?
  - Similarly, figure out how to serialize it back out.

- Parse multiple Set-Cookie headers in a single string

  - Need to check for when a non-known-attribute is introduced, though that also runs the risk of unknown attributes being counted as name=value pairs...

- Write some Fuzz tests for the serialization round-trips
  - Would neet a way to generate valid Attribute-values, and the possible serializations.
  - Not super useful probably, but a nice exercise :)

## Writing

Some things I'd love to write about:

- Think about where spaces belong in parsers. I am inclined to "lift them up", but sometimes that seems more convoluted. Reminds me of dangling padding/margin in CSS :D

- I love the API design around loops/sequences/explicit 'step'. The API guides you towards writing an efficient parser ("If you commit, there is no going back"). This is super interesting, because otherwise the process of factoring/refactoring/normalizing/"lifting things up", that I did in uni, can be daunting and very intuitive. I really like this API!
