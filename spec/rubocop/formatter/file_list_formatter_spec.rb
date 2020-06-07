# frozen_string_literal: true

RSpec.describe RuboCop::Formatter::FileListFormatter, :config do
  subject(:formatter) { described_class.new(output) }

  let(:output) { StringIO.new }

  let(:source) { %w[a b cdefghi].join("\n") }

  describe '#file_finished' do
    it 'displays parsable text' do
      rule.add_offense(
        nil,
        location: Parser::Source::Range.new(source_buffer, 0, 1),
        message: 'message 1'
      )
      rule.add_offense(
        nil,
        location: Parser::Source::Range.new(source_buffer, 9, 10),
        message: 'message 2'
      )

      formatter.file_finished('test', rule.offenses)
      formatter.file_finished('test_2', rule.offenses)
      expect(output.string).to eq "test\ntest_2\n"
    end
  end
end
