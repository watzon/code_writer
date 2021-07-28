require "./spec_helper"

Spectator.describe CodeWriter do
  let(io)     { IO::Memory.new }
  let(writer) { CodeWriter.new(buffer: io, newline_text: "\n", tab_count: 4)  }

  before_each { io.clear }

  describe "#print" do
    it "writes a string" do
      writer.print("this is a sentence")
      expect(writer.to_s).to eq("this is a sentence")
    end

    it "writes utf8 characters" do
      writer.print("😄❤️️😋")
      expect(writer.to_s).to eq("😄❤️️😋")
    end

    it "respects utf8 setting" do
      io.set_encoding("utf8")
      writer.utf8 = true
      writer.print("😄❤️️😋")
      expect { writer.to_s }.not_to raise_error(ArgumentError, "Invalid multibyte sequence")

      io.set_encoding("ascii")
      writer.utf8 = false
      writer.print("😄❤️️😋")
      expect { writer.to_s }.to raise_error(ArgumentError, "Invalid multibyte sequence")
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

  describe "#indent" do
    it "sets the indent level and writes a newline before next print" do
      writer.print("this is a sentence")
            .indent
            .print("this is indented")

      expect(writer.to_s).to eq("this is a sentence\n    this is indented")
    end

    it "can indent multiple times" do
      writer.print("this is a sentence")
            .indent(2)
            .print("this is indented")

      expect(writer.to_s).to eq("this is a sentence\n        this is indented")
    end

    it "accepts a block argument" do
      writer.print("this is a sentence").indent do
        writer.print("this is indented")
      end

      writer.print("this isn't")

      expect(writer.to_s).to eq("this is a sentence\n    this is indented\nthis isn't")
    end
  end

  describe "#dedent" do
    it "subtracts from the current indent level and writes a newline before next print" do
      writer.print("this is a sentence")
            .indent
            .print("this is indented")
            .dedent
            .print("this isn't")

      expect(writer.to_s).to eq("this is a sentence\n    this is indented\nthis isn't")
    end

    it "won't set the indent_level to less than 0" do
      writer.dedent(2)
      expect(writer.@indent_level).to eq(0)
    end
  end

  describe "#block" do
    subject(writer) { CodeWriter.new(buffer: io, newline_text: "\n", tab_count: 4, language_settings: language_settings)  }

    given language_settings = CodeWriter::LANGUAGES["crystal"]  do
      it "writes a block given the current language_settings" do
        writer.print("def foo").block do
          writer.print("print \"bar\"")
        end

        expect(writer.to_s).to eq("def foo\n    print \"bar\"\nend")
      end
    end

    given language_settings = CodeWriter::LANGUAGES["javascript"]  do
      it "writes a block given the current language_settings" do
        writer.print("function foo()").block do
          writer.print("console.log('bar');")
        end

        expect(writer.to_s).to eq("function foo() {\n    console.log('bar');\n}")
      end
    end
  end

  describe "#inline_block" do
    subject(writer) { CodeWriter.new(buffer: io, newline_text: "\n", tab_count: 4, language_settings: language_settings)  }

    given language_settings = CodeWriter::LANGUAGES["javascript"]  do
      it "writes an inine block given the current language_settings" do
        writer.print("function foo()").inline_block do
          writer.print("console.log('bar');")
        end

        expect(writer.to_s).to eq("function foo() { console.log('bar'); }")
      end
    end

    given language_settings = CodeWriter::LANGUAGES["python"]  do
      it "writes a normal block if the given language doesn't support inline blocks" do
        writer.print("def foo").inline_block do
          writer.print("print('bar')")
        end

        expect(writer.to_s).to eq("def foo:\n    print('bar')\n")
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
    subject(writer) { CodeWriter.new(buffer: io, newline_text: "\n", tab_count: 4, language_settings: language_settings)  }

    given language_settings = CodeWriter::LANGUAGES["crystal"] do
      it "writes a single line comment" do
        writer.comment("this is a single line comment")
        expect(writer.to_s).to eq("# this is a single line comment\n")
      end

      it "handles multiline comments for languages that don't support them" do
        writer.comment do
          writer.puts("we are now inside")
          writer.puts("of a multiline comment")
        end

        expect(writer.to_s).to eq("# we are now inside\n# of a multiline comment\n")
      end

      it "pads a multiline comment" do
        writer.comment(pad: true) do
          writer.puts("we are now inside")
          writer.puts("of a multiline comment")
        end

        expect(writer.to_s).to eq("#\n# we are now inside\n# of a multiline comment\n#\n")
      end
    end

    given language_settings = CodeWriter::LANGUAGES["javascript"] do
      it "writes a single line comment" do
        writer.comment("this is a single line comment")
        expect(writer.to_s).to eq("// this is a single line comment\n")
      end

      it "writes a multiline comment" do
        writer.comment do
          writer.puts("we are now inside")
          writer.puts("of a multiline comment")
        end

        expect(writer.to_s).to eq("/* we are now inside\nof a multiline comment */\n")
      end

      it "pads a multiline comment" do
        writer.comment(pad: true) do
          writer.puts("we are now inside")
          writer.puts("of a multiline comment")
        end

        expect(writer.to_s).to eq("/*\nwe are now inside\nof a multiline comment\n*/\n")
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
