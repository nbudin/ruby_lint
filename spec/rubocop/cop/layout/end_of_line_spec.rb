# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Layout::EndOfLine, :config do
  shared_examples 'all configurations' do
    it 'accepts an empty file' do
      inspect_source_file('')
      expect(rule.offenses.empty?).to be(true)
    end
  end

  shared_examples 'iso-8859-15' do |eol|
    it 'can inspect non-UTF-8 encoded source with proper encoding comment' do
      inspect_source_file(["# coding: ISO-8859-15#{eol}",
                           "# Euro symbol: \xa4#{eol}"].join("\n"))
      expect(rule.offenses.size).to eq(1)
    end
  end

  context 'when EnforcedStyle is native' do
    let(:rule_config) { { 'EnforcedStyle' => 'native' } }
    let(:messages) do
      ['Carriage return character ' \
        "#{RuboCop::Platform.windows? ? 'missing' : 'detected'}."]
    end

    it 'registers an offense for an incorrect EOL' do
      inspect_source_file(['x=0', '', "y=1\r"].join("\n"))
      expect(rule.messages).to eq(messages)
      expect(rule.offenses.map(&:line))
        .to eq([RuboCop::Platform.windows? ? 1 : 3])
    end
  end

  context 'when EnforcedStyle is crlf' do
    let(:rule_config) { { 'EnforcedStyle' => 'crlf' } }
    let(:messages) { ['Carriage return character missing.'] }

    include_examples 'all configurations'

    it 'registers an offense for CR+LF' do
      inspect_source_file(['x=0', '', "y=1\r"].join("\n"))
      expect(rule.messages).to eq(messages)
      expect(rule.offenses.map(&:line)).to eq([1])
    end

    it 'highlights the whole offending line' do
      inspect_source_file(['x=0', '', "y=1\r"].join("\n"))
      expect(rule.highlights).to eq(["x=0\n"])
    end

    it 'does not register offense for no CR at end of file' do
      inspect_source_file('x=0')
      expect(rule.offenses.empty?).to be(true)
    end

    it 'does not register offenses after __END__' do
      expect_no_offenses(<<~RUBY)
        x=0\r
        __END__
        x=0
      RUBY
    end

    context 'and there are many lines ending with LF' do
      it 'registers only one offense' do
        inspect_source_file(<<~RUBY)
          x=0

          y=1
        RUBY

        expect(rule.messages.size).to eq(1)
      end

      include_examples 'iso-8859-15', ''
    end

    context 'and the default external encoding is US_ASCII' do
      around do |example|
        orig_encoding = Encoding.default_external
        Encoding.default_external = Encoding::US_ASCII
        example.run
        Encoding.default_external = orig_encoding
      end

      it 'does not crash on UTF-8 encoded non-ascii characters' do
        source = ['class Epd::ReportsController < EpdAreaController',
                  "  'terecht bij uw ROM-coördinator.'",
                  'end'].join("\r\n")
        inspect_source_file(source)
        expect(rule.offenses.empty?).to be(true)
      end

      include_examples 'iso-8859-15', ''
    end

    context 'and source is a string' do
      it 'registers an offense' do
        inspect_source("x=0\ny=1")

        expect(rule.messages).to eq(['Carriage return character missing.'])
      end
    end
  end

  context 'when EnforcedStyle is lf' do
    let(:rule_config) { { 'EnforcedStyle' => 'lf' } }

    include_examples 'all configurations'

    it 'registers an offense for CR+LF' do
      inspect_source_file(['x=0', '', "y=1\r"].join("\n"))
      expect(rule.messages).to eq(['Carriage return character detected.'])
      expect(rule.offenses.map(&:line)).to eq([3])
    end

    it 'highlights the whole offending line' do
      inspect_source_file(['x=0', '', "y=1\r"].join("\n"))
      expect(rule.highlights).to eq(["y=1\r"])
    end

    it 'registers an offense for CR at end of file' do
      inspect_source_file("x=0\r")
      expect(rule.messages).to eq(['Carriage return character detected.'])
    end

    it 'does not register offenses after __END__' do
      expect_no_offenses(<<~RUBY)
        x=0
        __END__
        x=0\r
      RUBY
    end

    context 'and there are many lines ending with CR+LF' do
      it 'registers only one offense' do
        inspect_source_file(['x=0', '', 'y=1'].join("\r\n"))
        expect(rule.messages.size).to eq(1)
      end

      include_examples 'iso-8859-15', "\r"
    end

    context 'and the default external encoding is US_ASCII' do
      around do |example|
        orig_encoding = Encoding.default_external
        Encoding.default_external = Encoding::US_ASCII
        example.run
        Encoding.default_external = orig_encoding
      end

      it 'does not crash on UTF-8 encoded non-ascii characters' do
        source = ['class Epd::ReportsController < EpdAreaController',
                  "  'terecht bij uw ROM-coördinator.'",
                  'end'].join("\n")
        inspect_source_file(source)
        expect(rule.offenses.empty?).to be(true)
      end

      include_examples 'iso-8859-15', "\r"
    end

    context 'and source is a string' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          x=0\r
          ^^^ Carriage return character detected.
        RUBY
      end
    end
  end
end
