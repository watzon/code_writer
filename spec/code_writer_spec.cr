require "./spec_helper"

Spectator.describe CodeWriter do
  let(io) { IO::Memory.new }
  let(writer) { CodeWriter.new(buffer: io, newline_text: "\n", tab_count: 4) }

  before_each do
    io.clear
    writer.reset!
  end

  describe "#print" do
    it "writes a string" do
      writer.print("this is a sentence")
      expect(writer.to_s).to eq("this is a sentence")
    end

    it "writes utf8 characters" do
      writer.print("😄❤️️😋")
      expect(writer.to_s).to eq("😄❤️️😋")
    end

    it "writes a string with a trailing newline" do
      writer.print("this is a sentence\n")
      expect(writer.to_s).to eq("this is a sentence\n")
    end

    it "respects indentation" do
      writer.indent
      writer.print("this is indented")
      expect(writer.to_s).to eq("    this is indented")
    end
  end

  describe "#puts" do
    it "writes a string with a trailing newline" do
      writer.puts("this is a sentence")
      expect(writer.to_s).to eq("this is a sentence\n")
    end

    it "ends with a single trailing newline" do
      writer.puts("this is a sentence\n")
      expect(writer.to_s).to eq("this is a sentence\n")
    end

    it "only writes a newline if the string doesn't end with one" do
      writer.puts("this is a sentence\n")
      expect(writer.to_s).to eq("this is a sentence\n")
    end
  end

  describe "#print_if" do
    it "writes the string if the condition is true" do
      writer.print_if(true, "this is a sentence")
      expect(writer.to_s).to eq("this is a sentence")
    end

    it "doesn't print the string if the condition is false" do
      writer.print_if(false, "this is a sentence")
      expect(writer.to_s).to eq("")
    end
  end

  describe "#puts_if" do
    it "writes the string with a trailing newline if the condition is true" do
      writer.puts_if(true, "this is a sentence")
      expect(writer.to_s).to eq("this is a sentence\n")
    end

    it "doesn't print the string if the condition is false" do
      writer.puts_if(false, "this is a sentence")
      expect(writer.to_s).to eq("")
    end
  end

  describe "#indent" do
    it "sets the indent level and writes a newline before next print" do
      writer.puts("this is a sentence")
        .indent
        .puts("this is indented")

      expect(writer.to_s).to eq("this is a sentence\n    this is indented\n")
    end

    it "can indent multiple times" do
      writer.puts("this is a sentence")
        .indent(2)
        .puts("this is indented")

      expect(writer.to_s).to eq("this is a sentence\n        this is indented\n")
    end

    it "accepts a block argument" do
      writer.indent do
        writer.puts("this is indented")
        writer.puts("this is indented")
      end

      writer.puts("this isn't")

      expect(writer.to_s).to eq("    this is indented\n    this is indented\nthis isn't\n")
    end
  end

  describe "#dedent" do
    it "subtracts from the current indent level and writes a newline before next print" do
      writer.puts("this is a sentence")
        .indent
        .puts("this is indented")
        .dedent
        .puts("this isn't")

      expect(writer.to_s).to eq("this is a sentence\n    this is indented\nthis isn't\n")
    end

    it "won't set the indent_level to less than 0" do
      writer.dedent(2)
      expect(writer.@indent_level).to eq(0)
    end

    it "accepts a block argument" do
      writer.indent do
        writer.puts("this is indented")
        writer.puts("this is indented")

        writer.dedent do
          writer.puts("this isn't")
        end
      end

      expect(writer.to_s).to eq("    this is indented\n    this is indented\nthis isn't\n")
    end
  end

  describe "#block" do
    subject(writer) { CodeWriter.new(buffer: io, newline_text: "\n", tab_count: 4) }

    it "accepts an argument for the first line of the block" do
      writer.block("def foo") do
        writer.puts("puts \"bar\"")
      end

      expect(writer.to_s).to eq("def foo\n    puts \"bar\"\nend")
    end

    it "works with no first line argument" do
      writer.print("def foo").block do
        writer.puts("puts \"bar\"")
      end

      expect(writer.to_s).to eq("def foo\n    puts \"bar\"\nend")
    end

    describe "provided language settings, uses those settings" do
      subject(new_writer) { CodeWriter.new(buffer: io, newline_text: "\n", tab_count: 4, language_settings: language_settings) }

      provided language_settings: CodeWriter::LANGUAGES["crystal"] do
        new_writer.block("def foo") do
          new_writer.puts("puts \"bar\"")
        end

        expect(new_writer.to_s).to eq("def foo\n    puts \"bar\"\nend")
      end

      provided language_settings: CodeWriter::LANGUAGES["javascript"] do
        new_writer.block("function foo()") do
          new_writer.puts("console.log('bar');")
        end

        expect(new_writer.to_s).to eq("function foo() {\n    console.log('bar');\n}")
      end
    end
  end

  describe "#inline_block" do
    subject(new_writer) { CodeWriter.new(buffer: io, newline_text: "\n", tab_count: 4, language_settings: language_settings) }

    describe "provided language settings, uses those settings" do
      provided language_settings: CodeWriter::LANGUAGES["javascript"] do
        new_writer.inline_block("function foo()") do
          new_writer.print("console.log('bar');")
        end

        expect(new_writer.to_s).to eq("function foo() { console.log('bar'); }")
      end

      provided language_settings: CodeWriter::LANGUAGES["python"] do
        new_writer.inline_block("def foo") do
          new_writer.print("print('bar')")
        end

        expect(new_writer.to_s).to eq("def foo:\n    print('bar')\n")
      end
    end
  end

  describe "#newline" do
    it "writes a newline" do
      writer.print("this is on one line")
        .newline
        .print("this is on another")

      expect(writer.to_s).to eq("this is on one line\nthis is on another")
    end
  end

  describe "#blank_line" do
    it "writes a blank line" do
      writer.print("this is on one line")
        .blank_line
        .print("this is on another")

      expect(writer.to_s).to eq("this is on one line\n\nthis is on another")
    end
  end

  describe "#space" do
    it "writes a space" do
      writer.print("This is one sentence.")
        .space
        .print("This is another one.")

      expect(writer.to_s).to eq("This is one sentence. This is another one.")
    end
  end

  describe "#comment" do
    subject(new_writer) { CodeWriter.new(buffer: io, newline_text: "\n", tab_count: 4, language_settings: language_settings) }

    describe "single line comment" do
      provided language_settings: CodeWriter::LANGUAGES["crystal"] do
        new_writer.comment("this is a single line comment")
        expect(new_writer.to_s).to eq("# this is a single line comment\n")
      end

      provided language_settings: CodeWriter::LANGUAGES["javascript"] do
        new_writer.comment("this is a single line comment")
        expect(new_writer.to_s).to eq("// this is a single line comment\n")
      end
    end

    describe "multiline comments for languages that don't support them" do
      provided language_settings: CodeWriter::LANGUAGES["crystal"] do
        new_writer.comment do
          new_writer.puts("we are now inside")
          new_writer.puts("of a multiline comment")
        end

        expect(new_writer.to_s).to eq("# we are now inside\n# of a multiline comment\n")
      end

      provided language_settings: CodeWriter::LANGUAGES["javascript"] do
        new_writer.comment do
          new_writer.puts("we are now inside")
          new_writer.puts("of a multiline comment")
        end

        expect(new_writer.to_s).to eq("/* we are now inside\n * of a multiline comment\n */\n")
      end
    end

    describe "multiline comment padding" do
      provided language_settings: CodeWriter::LANGUAGES["crystal"] do
        new_writer.comment(pad: true) do
          new_writer.puts("we are now inside")
          new_writer.puts("of a multiline comment")
        end

        expect(new_writer.to_s).to eq("#\n# we are now inside\n# of a multiline comment\n#\n")
      end

      provided language_settings: CodeWriter::LANGUAGES["javascript"] do
        new_writer.comment(pad: true) do
          new_writer.puts("we are now inside")
          new_writer.puts("of a multiline comment")
        end

        expect(new_writer.to_s).to eq("/*\n * we are now inside\n * of a multiline comment\n*/\n")
      end
    end
  end

  describe "#last_n" do
    it "should return the last n characters as a string" do
      writer.print("this is a sentence")
      expect(writer.last_n(3)).to eq("nce")
    end

    it "should return available characters if n is longer than buffer" do
      writer.print("foo")
      expect(writer.last_n(5)).to eq("foo")
    end
  end
end
