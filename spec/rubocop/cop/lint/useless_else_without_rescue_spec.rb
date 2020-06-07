# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Lint::UselessElseWithoutRescue do
  subject(:cop) { described_class.new }

  context 'with `else` without `rescue`' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        begin
          do_something
        else
        ^^^^ `else` without `rescue` is useless.
          handle_unknown_errors
        end
      RUBY
    end
  end

  context 'with `else` with `rescue`' do
    it 'accepts' do
      expect_no_offenses(<<~RUBY)
        begin
          do_something
        rescue ArgumentError
          handle_argument_error
        else
          handle_unknown_errors
        end
      RUBY
    end
  end
end
