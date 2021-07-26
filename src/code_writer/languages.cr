class CodeWriter
  record LanguageSettings,
    block_start : String,
    block_end : String,
    comment_start : String,
    inline_block_start : String? = nil,
    inline_block_end : String? = nil,
    multiline_comment_start : String? = nil,
    multiline_comment_end : String? = nil,
    space_before_block_start : Bool = true do

    def supports_inline_block?
      self.inline_block_start && self.inline_block_end
    end

    def supports_multiline_comments?
      self.multiline_comment_start && self.multiline_comment_end
    end
  end

  LANGUAGES = {
    "crystal" => LanguageSettings.new(
      block_start: "",
      block_end: "end",
      inline_block_start: "{",
      inline_block_end: "}",
      comment_start: "#",
      space_before_block_start: false,
    ),
    "python" => LanguageSettings.new(
      block_start: ":",
      block_end: "",
      comment_start: "#",
      space_before_block_start: false,
    ),
    "c" => LanguageSettings.new(
      block_start: "{",
      block_end: "}",
      inline_block_start: "{",
      inline_block_end: "}",
      comment_start: "//",
      multiline_comment_start: "/*",
      multiline_comment_end: "*/",
      space_before_block_start: true,
    ),
    "c++" => LanguageSettings.new(
      block_start: "{",
      block_end: "}",
      inline_block_start: "{",
      inline_block_end: "}",
      comment_start: "//",
      multiline_comment_start: "/*",
      multiline_comment_end: "*/",
      space_before_block_start: true,
    ),
    "c#" => LanguageSettings.new(
      block_start: "{",
      block_end: "}",
      inline_block_start: "{",
      inline_block_end: "}",
      comment_start: "//",
      multiline_comment_start: "/*",
      multiline_comment_end: "*/",
      space_before_block_start: true,
    ),
    "java" => LanguageSettings.new(
      block_start: "{",
      block_end: "}",
      inline_block_start: "{",
      inline_block_end: "}",
      comment_start: "//",
      multiline_comment_start: "/*",
      multiline_comment_end: "*/",
      space_before_block_start: true,
    ),
    "javascript" => LanguageSettings.new(
      block_start: "{",
      block_end: "}",
      inline_block_start: "{",
      inline_block_end: "}",
      comment_start: "//",
      multiline_comment_start: "/*",
      multiline_comment_end: "*/",
      space_before_block_start: true,
    ),
    "typescript" => LanguageSettings.new(
      block_start: "{",
      block_end: "}",
      inline_block_start: "{",
      inline_block_end: "}",
      comment_start: "//",
      multiline_comment_start: "/*",
      multiline_comment_end: "*/",
      space_before_block_start: true,
    ),
  }

  EXTENSION_TO_LANGUAGE = {
    "cr" => LANGUAGES["crystal"],
    "py" => LANGUAGES["python"],
    "js" => LANGUAGES["javascript"],
    "jsx" => LANGUAGES["javascript"],
    "ejs" => LANGUAGES["javascript"],
    "ts" => LANGUAGES["typescript"],
    "tsx" => LANGUAGES["typescript"],
    "c" => LANGUAGES["c"],
    "c++" => LANGUAGES["c++"],
    "c#" => LANGUAGES["c#"],
    "java" => LANGUAGES["java"],
  }
end
