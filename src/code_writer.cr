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
  property utf8 : Bool = true

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

  delegate :block_start,
           :block_end,
           :comment_start,
           :inline_block_start,
           :inline_block_end,
           :multiline_comment_start,
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

  # Write text to the internal buffer.
  def print(str, format_args : Array | Tuple | Nil = nil)
    string = String.build do |s|
      if (self.last_newline? || self.pos == 0)
        # Handle being within a comment
        if self.in_multiline_comment?
          if self.supports_multiline_comments?
            # s << (CHARS["space"] * (self.multiline_comment_start.size + 1))
          else
            s << self.comment_start
            s << CHARS["space"]
          end
        end

        # Handle indentation
        if self.indent_level > 0
          s << self.indent_text * self.indent_level
        end
      end

      # Write the given string
      if format_args
        s.printf(str, format_args)
      else
        s.print(str)
      end

      # Handle newline
      if self.newline_next_write?
        s << self.newline_text
        self.newline_next_write = false
      end
    end

    # Write the buffer to the IO
    buffer = string.to_s.to_slice
    self.utf8 ?
      self.buffer.write_utf8(buffer) :
      self.buffer.write(buffer)

    self.buffer.flush
    self
  end

  # :ditto:
  def print(str, *args)
    print(str, args)
  end

  # Write text with a trailing newline, assuming the text doesn't already
  # end with a newline.
  def puts(str, format_args = nil)
    print(str, format_args).print_if(!self.last_newline?, self.newline_text)
  end

  # :ditto:
  def puts(str, *args)
    puts(str, args)
  end

  # Writes text, only if the condition is true.
  def print_if(condition : Bool, str : String | Char | Bytes, format_args = nil)
    self.print(str, format_args) if condition
    self
  end

  def print_if(condition, str, *args)
    print_if(condition, str, args)
  end

  # Set the indentation level for the next lines and print a newline.
  #
  # ```
  # writer.print("def foo")
  #       .indent
  #       .print("# do something")
  #       .dedent
  #       .print("end")
  # ```
  def indent(amount : Int32 = 1)
    self.newline
    self.set_indent(self.indent_level + amount)
    self
  end

  # Set the indentation level for the given block, then reset it
  # once the block exits.
  #
  # ```
  # writer.print("def foo").indent do
  #   writer.print("# do something")
  # end
  # ```
  def indent(amount : Int32 = 1, &block : ->)
    self.indent(amount)
    yield
    self.dedent(amount)
    self
  end

  def dedent(amount : Int32 = 1)
    self.set_indent(self.indent_level - amount)
    self.newline
    self
  end

  def block(&block : ->)
    self.print_if(self.space_before_block_start, CHARS["space"])
        .print(self.block_start)
        .indent(&block)
        .print(self.block_end)
    self
  end

  def inline_block(&block : ->)
    return self.block(&block) unless self.language_settings.supports_inline_block?

    self.print_if(self.space_before_block_start, CHARS["space"])
        .print(self.inline_block_start.not_nil!)
        .print(CHARS["space"])

        yield

    self.print(CHARS["space"])
        .print(self.inline_block_end.not_nil!)

    self
  end

  def newline
    self.newline_next_write = false
    self.print(self.newline_text)
    self
  end

  def newline_if_last_not
    self.newline if !self.last_newline?
    self
  end

  def blank_line
    self.newline_if_last_not.newline
  end

  def blank_line_if_last_not
    self.blank_line if !self.last_blank_line?
    self
  end

  def space(count : Int32 = 1)
    print(CHARS["space"].to_s * count)
    self
  end

  def comment(str)
    self.print(self.comment_start)
        .space
        .print(str)
        .newline_if_last_not
    self
  end

  def comment(*, pad : Bool = false, &block : ->)
    if self.supports_multiline_comments?
      self.print(self.multiline_comment_start)
          .print_if(!pad, CHARS["space"])

      self.newline_if_last_not if pad
      self.in_multiline_comment = true

      yield

      self.in_multiline_comment = false

      if pad
        self.newline_if_last_not
      elsif (nl = self.last_newline?)
        self.set_pos(self.pos - nl.to_s.size)
      end

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

  def set_indent(level : Int32)
    self.indent_level = Math.max(0, level)
    self
  end

  # Get the indentation string given the current indent level.
  def indent_text
    self.indent_style.to_s * self.tab_count
  end

  def last_newline?
    if (match = last_n(2).match(/(\r\n)|.(\n)/))
      match[1]? || match[2]
    else
      false
    end
  end

  def last_blank_line?
    if (match = last_n(4).match(/(\r\n\r\n)|..(\n\n)/))
      match[1]? || match[2]
    else
      false
    end
  end

  def last_n(bytes : Int32 = 1)
    pos = self.buffer.pos # current buffer position
    newpos = Math.max(0, pos - bytes) # current position - bytes
    self.buffer.pos = newpos
    self.buffer.read_string(pos - newpos)
  end

  def set_pos(pos)
    @buffer.pos = pos
  end

  def pos
    @buffer.pos
  end

  def size
    @buffer.pos
  end

  def to_s
    @buffer.rewind
    buffer.gets_to_end
  end
end
