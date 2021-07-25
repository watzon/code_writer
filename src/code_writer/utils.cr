class CodeWriter
  NEWLINE_RE = /(\r?\n)/

  def self.escape_quote(str : String, quote : Char)
    self.escape_char(str, quote).gsub(NEWLINE_RE, "\\$1")
  end

  def self.escape_char(str : String, char : Char)
    String.build do |s|
      str.chars.each do |ch|
        s << "\\" if ch == char
        s << ch
      end
    end
  end

  def self.get_string(string : String | -> String)
    return string if string.is_a?(String)
    string.call()
  end
end
