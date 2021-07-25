require "./code_writer/utils"

# TODO: Write documentation for `CodeWriter`
class CodeWriter
  CHARS = {
    BACK_SLASH: '\\',
    FORWARD_SLASH: '/',
    NEW_LINE: '\n',
    CARRIAGE_RETURN: '\r',
    ASTERISK: '*',
    DOUBLE_QUOTE: '"',
    SINGLE_QUOTE: '\'',
    BACK_TICK: '`',
    OPEN_BRACE: '{',
    CLOSE_BRACE: '}',
    DOLLAR_SIGN: '$',
    SPACE: ' ',
    TAB: '\t',
  }

  SHOULD_HANDLE = Set.new([
    CHARS.BACK_SLASH,
    CHARS.FORWARD_SLASH,
    CHARS.NEW_LINE,
    CHARS.CARRIAGE_RETURN,
    CHARS.ASTERISK,
    CHARS.DOUBLE_QUOTE,
    CHARS.SINGLE_QUOTE,
    CHARS.BACK_TICK,
    CHARS.OPEN_BRACE,
    CHARS.CLOSE_BRACE,
  ])

  enum QuoteStyle
    Single
    Double
  end

  enum CommentStyle
    DoubleSlash
    TripleSlash
    SlashStar
    Hash
    Semicolon
  end

  enum IndentStyle
    Tab
    String

    def self.char
      case self
      in Tabs
        '\t'
      in Spaces
        ' '
      end
    end
  end

  private property newline_text : String
  private property quote_style : QuoteStyle
  private property indent_style : IndentStyle
  private property comment_style : CommentStyle
  private property tab_count : Int32
  private property current_indent : Int32
  private property queued_indent : Int32?
  private property length : Int32
  private property string_char_stack : Array(Int32)
  private property buffer : IO

  private property? queued_only_if_not_block : Bool
  private property? newline_on_next_write : Bool
  private property? in_regex : Bool
  private property? first_line_of_block : Bool

  def initialize(
    *,
    @buffer : IO = IO::Memory.new,
    @newline_text : String = "\n",
    @tab_count : Int32 = 4,
    @indent_style : IndentStyle = IndentStyle::Spaces,
    @quote_style : QuoteStyle = QuoteStyle::Double,
    @comment_style : CommentStyle = CommentStyle::Hash,
  )
    @current_indent = 0
    @queued_indent = 0
    @queued_only_if_not_block = false
    @newline_on_next_write = false
    @current_comment_char = nil
    @in_regex = false
    @first_line_of_block = true
  end

  # Set the indentation for the next lines written.
  def indent(level : Int32)

  end

  def indent_string
    self.indent_style.char * self.tab_count
  end
end
