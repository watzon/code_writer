require "./code_writer/utils"
require "./code_writer/languages"

# TODO: Write documentation for `CodeWriter`
class CodeWriter
  CHARS = {
    "back_slash": '\\',
    "forward_slash": '/',
    "newline": '\n',
    "carriage_return": '\r',
    "asterisk": '*',
    "double_quote": '"',
    "single_quote": '\'',
    "back_tick": '`',
    "open_brace": '{',
    "close_brace": '}',
    "dollar_sign": '$',
    "space": ' ',
    "tab": '\t',
  }

  SHOULD_HANDLE = Set.new([
    CHARS["back_slash"],
    CHARS["forward_slash"],
    CHARS["new_line"],
    CHARS["carriage_return"],
    CHARS["asterisk"],
    CHARS["double_quote"],
    CHARS["single_quote"],
    CHARS["back_tick"],
    CHARS["open_brace"],
    CHARS["close_brace"],
  ])

  enum QuoteStyle
    Single
    Double
  end

  enum IndentStyle
    Tabs
    Spaces

    def to_s
      case self
      in Tabs
        CHARS["tab"].to_s
      in Spaces
        CHARS["space"].to_s
      end
    end
  end

  property language_settings : LanguageSettings

  private property newline_text : String
  private property quote_style : QuoteStyle
  private property indent_style : IndentStyle
  private property tab_count : Int32
  private property buffer : IO
  private property indent_level : Int32 = 0

  private property? in_string : Bool = false
  private property? in_multiline_comment : Bool = false
  private property? first_line_of_block : Bool = true
  private property? newline_next_write : Bool = false
  private property? last_newline : Bool = false

  delegate :block_start,
           :block_end,
           :comment_start,
           :inline_block_start,
           :inline_block_end,
           :multiline_comment_start,
           :multiline_comment_middle,
           :multiline_comment_end,
           :supports_multiline_comments?,
           :supports_inline_block?,
           :space_before_block_start,
           to: @language_settings

  def initialize(
    *,
    @buffer : IO = IO::Memory.new,
    @newline_text : String = "\n",
    @tab_count : Int32 = 4,
    @indent_style : IndentStyle = IndentStyle::Spaces,
    @quote_style : QuoteStyle = QuoteStyle::Double,
    @language_settings : LanguageSettings = LANGUAGES["crystal"],
  )
  end

  # Reset the internal state of the writer.
  # Note: Does not clear the internal buffer.
  def reset!
    self.in_string = false
    self.in_multiline_comment = false
    self.first_line_of_block = true
    self.newline_next_write = false
    self.last_newline = false
    self.indent_level = 0
    self
  end

  # Write text to the internal buffer. Respects the current indentation level, and will indent the line if the
  # `last_newline` flag is set.
  def print(str)
    str = str.to_s

    # If we're at the start of a new line, or if we're at the start of the file, indent the line.
    if self.last_newline? || self.buffer.pos.zero?
      self.last_newline = false
      self.buffer.print(indent_text)

      # If we are in a multiline comment, we need to add a comment prefix to the line.
      if self.in_multiline_comment?
        if middle = self.multiline_comment_middle
          self.buffer.print(middle)
        elsif self.supports_multiline_comments?
          # just indent
          self.buffer.print(self.indent_text)
        else
          self.buffer.print(self.comment_start)
        end
        self.buffer.print(" ")
      end
    end

    self.buffer.print(str)

    # Set the `last_newline` flag if the text ends with a newline.
    self.last_newline = str.ends_with?(self.newline_text)
    self
  end

  # Write text to the internal buffer, using additional args as format arguments.
  # Respects the current indentation level, and will indent the line if the
  # `last_newline` flag is set.
  def print(str, *args)
    self.print(str.to_s % args)
  end

  # Writes text, only if the condition is true.
  def print_if(condition, str)
    self.print(str) if condition
    self
  end

  def print_if(condition, str, *args)
    print_if(condition, str.to_s % args)
  end

  # Write text with a trailing newline, assuming the text doesn't already
  # end with a newline.
  def puts(str)
    print(str).print_if(!self.last_newline?, self.newline_text)
  end

  # Write text with a trailing newline, assuming the text doesn't already
  # end with a newline. Uses additional args as format arguments.
  def puts(str, *args)
    self.puts(str.to_s % args)
  end

  # Write text with a trailing newline, only if the condition is true.
  def puts_if(condition, str)
    self.puts(str) if condition
    self
  end

  def puts_if(condition, str, *args)
    puts_if(condition, str.to_s % args)
  end

  # Set the indentation level for the next lines.
  def indent(amount : Int32 = 1)
    self.set_indent(self.indent_level + amount)
  end

  # Set the indentation level for the given block, then reset it
  # once the block exits.
  def indent(amount : Int32 = 1, &block : ->)
    self.set_indent(self.indent_level + amount)
    yield
    self.set_indent(self.indent_level - amount)
  end

  # Subtract from the indentation level for the next lines.
  def dedent(amount : Int32 = 1)
    self.set_indent(self.indent_level - amount)
    self
  end

  # Subtract from the indentation level for the given block, then reset it
  # once the block exits.
  def dedent(amount : Int32 = 1, &block : ->)
    self.set_indent(self.indent_level - amount)
    yield
    self.set_indent(self.indent_level + amount)
  end

  # Create a block using the current language's block syntax. Sets the correct
  # opening and closing characters, and indents the block contents.
  #
  # ```
  # writer.puts("def foo").block do
  #   writer.puts("# do something")
  # end
  # ```
  #
  # This will output:
  #
  # ```
  # def foo
  #   # do something
  # end
  # ```
  def block(first_line = nil, &block : ->)
    self.print_if(!first_line.nil?, first_line)
        .print_if(self.space_before_block_start, CHARS["space"])
        .print(self.block_start)
        .print_if(!self.last_newline?, self.newline_text)
        .indent(&block)
        .newline_if_last_not
        .print(self.block_end)
  end

  # Create an inline block using the current language's block syntax. Sets the correct
  # opening and closing characters, and keeps the block contents on the same line.
  #
  # ```
  # writer.print("foo.bar").inline_block do
  #   writer.print("|x| x + 1")
  # end
  # ```
  #
  # This will output:
  #
  # ```
  # foo.bar { |x| x + 1 }
  # ```
  def inline_block(pre_block = nil, &block : ->)
    return self.block(pre_block, &block) unless self.language_settings.supports_inline_block?

    self.print_if(!pre_block.nil?, pre_block)
        .print_if(self.space_before_block_start, CHARS["space"])
        .print(self.inline_block_start.not_nil!)
        .print(CHARS["space"])

    yield

    self.print(CHARS["space"])
        .print(self.inline_block_end.not_nil!)

    self
  end

  # Add a newline to the internal buffer.
  def newline
    self.newline_next_write = false
    self.print(self.newline_text)
    self
  end

  # Add a newline to the internal buffer, only if the last character written was not a newline.
  def newline_if_last_not
    self.newline if !self.last_newline?
    self
  end

  # Add a blank line to the internal buffer.
  def blank_line
    self.newline_if_last_not.newline
  end

  # Add a blank line to the internal buffer, only if the last character written was not a newline.
  def blank_line_if_last_not
    self.blank_line if !self.last_blank_line?
    self
  end

  # Add a space to the internal buffer.
  def space(count : Int32 = 1)
    print(CHARS["space"].to_s * count)
    self
  end

  # Create a single comment using the current language's comment syntax.
  #
  # ```
  # writer.comment("This is a comment")
  # ```
  #
  # This will output:
  #
  # ```
  # # This is a comment
  # ```
  def comment(str)
    self.print(self.comment_start)
        .space
        .print(str)
        .newline_if_last_not
    self
  end

  # Create a multiline comment using the current language's comment syntax.
  #
  # ```
  # writer.comment do
  #   writer.print("This is a comment")
  #   writer.print("This is another comment")
  # end
  # ```
  #
  # This will output:
  #
  # ```
  # # This is a comment
  # # This is another comment
  # ```
  def comment(*, pad : Bool = false, &block : ->)
    if self.supports_multiline_comments?
      self.print(self.multiline_comment_start)
          .print_if(!pad, CHARS["space"])

      self.newline_if_last_not if pad
      self.in_multiline_comment = true

      yield

      self.in_multiline_comment = false

      self.newline_if_last_not if pad

      self.print_if(!pad, CHARS["space"])
          .puts(self.multiline_comment_end)

      self.newline_if_last_not
    else
      self.print(self.comment_start).newline if pad
      self.in_multiline_comment = true

      yield

      self.in_multiline_comment = false
      self.newline_if_last_not.print(self.comment_start) if pad

      self.newline_if_last_not
    end
  end

  # Set the indent level.
  def set_indent(level : Int32)
    self.indent_level = Math.max(0, level)
    self
  end

  # Get the indentation string given the current indent level.
  def indent_text
    (self.indent_style.to_s * self.tab_count) * self.indent_level
  end

  # Get the last n bytes from the internal buffer.
  def last_n(bytes : Int32 = 1)
    pos = self.buffer.pos # current buffer position
    newpos = Math.max(0, pos - bytes) # current position - bytes
    self.buffer.pos = newpos
    self.buffer.read_string(pos - newpos)
  end

  # Set the position of the internal buffer.
  def set_pos(pos)
    @buffer.pos = pos
  end

  # Get the position of the internal buffer.
  def pos
    @buffer.pos
  end

  # Get the size of the internal buffer.
  def size
    @buffer.pos
  end

  # Get the contents of the internal buffer.
  def to_s
    @buffer.rewind
    buffer.gets_to_end
  end
end
