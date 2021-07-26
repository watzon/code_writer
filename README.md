# CodeWriter

Crystal utility class for generating code.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     code_writer:
       github: watzon/code_writer
   ```

2. Run `shards install`

## Usage

```crystal
require "code_writer"

# Create a new writer (showing default options)
writer = CodeWriter.new(
  buffer: IO::Memory.new,
  newline_text: "\n",
  tab_count: 4,
  indent_style: :spaces,
  quote_style: :double,
  language_settings: CodeWriter::LANGUAGES["crystal"],
)

# Write code to the buffer
writer.comment do
  writer.write_line("This is a comment")
  writer.write_line("This comment is on another line")
end

writer.blank_line

writer.write("class Foo").block do
  writer.write("def bar").block do
    writer.write_line("print \"baz\"")
  end
end

# Convert the buffer to a string
writer.to_s
```

## Contributing

1. Fork it (<https://github.com/watzon/code_writer/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
