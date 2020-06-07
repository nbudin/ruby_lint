# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::TrailingCommaInArrayLiteral, :config do
  shared_examples 'single line lists' do |extra_info|
    it 'registers an offense for trailing comma' do
      expect_offense(<<~RUBY)
        VALUES = [1001, 2020, 3333, ]
                                  ^ Avoid comma after the last item of an array#{extra_info}.
      RUBY
    end

    it 'accepts literal without trailing comma' do
      expect_no_offenses('VALUES = [1001, 2020, 3333]')
    end

    it 'accepts single element literal without trailing comma' do
      expect_no_offenses('VALUES = [1001]')
    end

    it 'accepts empty literal' do
      expect_no_offenses('VALUES = []')
    end

    it 'accepts rescue clause' do
      # The list of rescued classes is an array.
      expect_no_offenses(<<~RUBY)
        begin
          do_something
        rescue RuntimeError
        end
      RUBY
    end

    it 'auto-corrects unwanted comma in literal' do
      new_source = autocorrect_source('VALUES = [1001, 2020, 3333, ]')
      expect(new_source).to eq('VALUES = [1001, 2020, 3333 ]')
    end
  end

  context 'with single line list of values' do
    context 'when EnforcedStyleForMultiline is no_comma' do
      let(:rule_config) { { 'EnforcedStyleForMultiline' => 'no_comma' } }

      include_examples 'single line lists', ''
    end

    context 'when EnforcedStyleForMultiline is comma' do
      let(:rule_config) { { 'EnforcedStyleForMultiline' => 'comma' } }

      include_examples 'single line lists',
                       ', unless each item is on its own line'
    end

    context 'when EnforcedStyleForMultiline is consistent_comma' do
      let(:rule_config) { { 'EnforcedStyleForMultiline' => 'consistent_comma' } }

      include_examples 'single line lists',
                       ', unless items are split onto multiple lines'
    end
  end

  context 'with multi-line list of values' do
    context 'when EnforcedStyleForMultiline is no_comma' do
      let(:rule_config) { { 'EnforcedStyleForMultiline' => 'no_comma' } }

      it 'registers an offense for trailing comma' do
        expect_offense(<<~RUBY)
          VALUES = [
                     1001,
                     2020,
                     3333,
                         ^ Avoid comma after the last item of an array.
                   ]
        RUBY
      end

      it 'accepts a literal with no trailing comma' do
        expect_no_offenses(<<~RUBY)
          VALUES = [ 1001,
                     2020,
                     3333 ]
        RUBY
      end

      it 'auto-corrects unwanted comma' do
        new_source = autocorrect_source(<<~RUBY)
          VALUES = [
                     1001,
                     2020,
                     3333,
                   ]
        RUBY
        expect(new_source).to eq(<<~RUBY)
          VALUES = [
                     1001,
                     2020,
                     3333
                   ]
        RUBY
      end

      it 'accepts HEREDOC with commas' do
        expect_no_offenses(<<~RUBY)
          [
            <<-TEXT, 123
              Something with a , in it
            TEXT
          ]
        RUBY
      end

      it 'auto-corrects unwanted comma where HEREDOC has commas' do
        new_source = autocorrect_source(<<~RUBY)
          [
            <<-TEXT, 123,
              Something with a , in it
            TEXT
          ]
        RUBY
        expect(new_source).to eq(<<~RUBY)
          [
            <<-TEXT, 123
              Something with a , in it
            TEXT
          ]
        RUBY
      end
    end

    context 'when EnforcedStyleForMultiline is comma' do
      let(:rule_config) { { 'EnforcedStyleForMultiline' => 'comma' } }

      context 'when closing bracket is on same line as last value' do
        it 'accepts literal with no trailing comma' do
          expect_no_offenses(<<~RUBY)
            VALUES = [
                       1001,
                       2020,
                       3333]
          RUBY
        end
      end

      it 'accepts literal with two of the values on the same line' do
        expect_no_offenses(<<~RUBY)
          VALUES = [
                     1001, 2020,
                     3333
                   ]
        RUBY
      end

      it 'registers an offense for a literal with two of the values ' \
         'on the same line and a trailing comma' do
        expect_offense(<<~RUBY)
          VALUES = [
                     1001, 2020,
                     3333,
                         ^ Avoid comma after the last item of an array, unless each item is on its own line.
                   ]
        RUBY
      end

      it 'accepts trailing comma' do
        expect_no_offenses(<<~RUBY)
          VALUES = [1001,
                    2020,
                    3333,
                   ]
        RUBY
      end

      it 'accepts a multiline word array' do
        expect_no_offenses(<<~RUBY)
          ingredients = %w(
            sausage
            anchovies
            olives
          )
        RUBY
      end

      it 'accepts an empty array being passed as a method argument' do
        expect_no_offenses(<<~RUBY)
          Foo.new([
                   ])
        RUBY
      end

      it 'auto-corrects literal with two of the values on the same' \
         ' line and a trailing comma' do
        new_source = autocorrect_source(<<~RUBY)
          VALUES = [
                     1001, 2020,
                     3333
                   ]
        RUBY
        expect(new_source).to eq(<<~RUBY)
          VALUES = [
                     1001, 2020,
                     3333
                   ]
        RUBY
      end

      it 'accepts a multiline array with a single item and trailing comma' do
        expect_no_offenses(<<~RUBY)
          foo = [
            1,
          ]
        RUBY
      end
    end

    context 'when EnforcedStyleForMultiline is consistent_comma' do
      let(:rule_config) { { 'EnforcedStyleForMultiline' => 'consistent_comma' } }

      context 'when closing bracket is on same line as last value' do
        it 'registers an offense for no trailing comma' do
          expect_offense(<<~RUBY)
            VALUES = [
                       1001,
                       2020,
                       3333]
                       ^^^^ Put a comma after the last item of a multiline array.
          RUBY
        end
      end

      it 'accepts two values on the same line' do
        expect_no_offenses(<<~RUBY)
          VALUES = [
                     1001, 2020,
                     3333,
                   ]
        RUBY
      end

      it 'registers an offense for literal with two of the values ' \
         'on the same line and no trailing comma' do
        expect_offense(<<~RUBY)
          VALUES = [
                     1001, 2020,
                     3333
                     ^^^^ Put a comma after the last item of a multiline array.
                   ]
        RUBY
      end

      it 'accepts trailing comma' do
        expect_no_offenses(<<~RUBY)
          VALUES = [1001,
                    2020,
                    3333,
                   ]
        RUBY
      end

      it 'accepts a multiline word array' do
        expect_no_offenses(<<~RUBY)
          ingredients = %w(
            sausage
            anchovies
            olives
          )
        RUBY
      end

      it 'auto-corrects a literal with two of the values on the same' \
         ' line and a trailing comma' do
        new_source = autocorrect_source(<<~RUBY)
          VALUES = [
                     1001, 2020,
                     3333
                   ]
        RUBY
        expect(new_source).to eq(<<~RUBY)
          VALUES = [
                     1001, 2020,
                     3333,
                   ]
        RUBY
      end

      it 'accepts a multiline array with a single item and trailing comma' do
        expect_no_offenses(<<~RUBY)
          foo = [
            1,
          ]
        RUBY
      end

      it 'accepts a multiline array with items on a single line and' \
         'trailing comma' do
        expect_no_offenses(<<~RUBY)
          foo = [
            1, 2,
          ]
        RUBY
      end
    end
  end
end
