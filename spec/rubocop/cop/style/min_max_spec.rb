# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Style::MinMax, :config do
  context 'with an array literal containing calls to `#min` and `#max`' do
    context 'when the expression stands alone' do
      it 'registers an offense if the receivers match' do
        expect_offense(<<~RUBY)
          [foo.min, foo.max]
          ^^^^^^^^^^^^^^^^^^ Use `foo.minmax` instead of `[foo.min, foo.max]`.
        RUBY
      end

      it 'does not register an offense if the receivers do not match' do
        expect_no_offenses(<<~RUBY)
          [foo.min, bar.max]
        RUBY
      end

      it 'does not register an offense if there are additional elements' do
        expect_no_offenses(<<~RUBY)
          [foo.min, foo.baz, foo.max]
        RUBY
      end

      it 'does not register an offense if the receiver is implicit' do
        expect_no_offenses(<<~RUBY)
          [min, max]
        RUBY
      end

      it 'auto-corrects an offense to use `#minmax`' do
        corrected = autocorrect_source(<<~RUBY)
          [foo.bar.min, foo.bar.max]
        RUBY

        expect(corrected).to eq(<<~RUBY)
          foo.bar.minmax
        RUBY
      end
    end

    context 'when the expression is used in a parallel assignment' do
      it 'registers an offense if the receivers match' do
        expect_offense(<<~RUBY)
          bar = foo.min, foo.max
                ^^^^^^^^^^^^^^^^ Use `foo.minmax` instead of `foo.min, foo.max`.
        RUBY
      end

      it 'does not register an offense if the receivers do not match' do
        expect_no_offenses(<<~RUBY)
          baz = foo.min, bar.max
        RUBY
      end

      it 'does not register an offense if there are additional elements' do
        expect_no_offenses(<<~RUBY)
          bar = foo.min, foo.baz, foo.max
        RUBY
      end

      it 'does not register an offense if the receiver is implicit' do
        expect_no_offenses(<<~RUBY)
          bar = min, max
        RUBY
      end

      it 'auto-corrects an offense to use `#minmax`' do
        corrected = autocorrect_source(<<~RUBY)
          baz = foo.bar.min, foo.bar.max
        RUBY

        expect(corrected).to eq(<<~RUBY)
          baz = foo.bar.minmax
        RUBY
      end
    end

    context 'when the expression is used as a return value' do
      it 'registers an offense if the receivers match' do
        expect_offense(<<~RUBY)
          return foo.min, foo.max
                 ^^^^^^^^^^^^^^^^ Use `foo.minmax` instead of `foo.min, foo.max`.
        RUBY
      end

      it 'does not register an offense if the receivers do not match' do
        expect_no_offenses(<<~RUBY)
          return foo.min, bar.max
        RUBY
      end

      it 'does not register an offense if there are additional elements' do
        expect_no_offenses(<<~RUBY)
          return foo.min, foo.baz, foo.max
        RUBY
      end

      it 'does not register an offense if the receiver is implicit' do
        expect_no_offenses(<<~RUBY)
          return min, max
        RUBY
      end

      it 'auto-corrects an offense to use `#minmax`' do
        corrected = autocorrect_source(<<~RUBY)
          return foo.bar.min, foo.bar.max
        RUBY

        expect(corrected).to eq(<<~RUBY)
          return foo.bar.minmax
        RUBY
      end
    end
  end
end
