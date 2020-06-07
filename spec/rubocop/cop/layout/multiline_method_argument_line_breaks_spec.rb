# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Layout::MultilineMethodArgumentLineBreaks do
  subject(:rule) { described_class.new }

  context 'when one argument on same line' do
    it 'does not add any offenses' do
      expect_no_offenses(<<~RUBY)
        taz("abc")
      RUBY
    end
  end

  context 'when bracket hash assignment on multiple lines' do
    it 'does not add any offenses' do
      expect_no_offenses(<<~RUBY)
        class Thing
          def call
            bar['foo'] = ::Time.zone.at(
                           huh['foo'],
                         )
          end
        end
      RUBY
    end
  end

  context 'when bracket hash assignment key on multiple lines' do
    it 'does not add any offenses' do
      expect_no_offenses(<<~RUBY)
        a['b',
            'c', 'd'] = e
      RUBY
    end
  end

  context 'when two arguments are on next line' do
    it 'does not add any offenses' do
      expect_no_offenses(<<~RUBY)
        taz(
          "abc", "foo"
        )
      RUBY
    end
  end

  context 'when many arguments are on multiple lines, two on same line' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        taz("abc",
        "foo", "bar",
               ^^^^^ Each argument in a multi-line method call must start on a separate line.
        "baz"
        )
      RUBY

      expect_correction(<<~RUBY)
        taz("abc",
        "foo",\s
        "bar",
        "baz"
        )
      RUBY
    end
  end

  context 'when many arguments are on multiple lines, three on same line' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        taz("abc",
        "foo", "bar", "barz",
                      ^^^^^^ Each argument in a multi-line method call must start on a separate line.
               ^^^^^ Each argument in a multi-line method call must start on a separate line.
        "baz"
        )
      RUBY

      expect_correction(<<~RUBY)
        taz("abc",
        "foo",\s
        "bar",\s
        "barz",
        "baz"
        )
      RUBY
    end
  end

  context 'when many arguments including hash are on multiple lines, three on same line' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        taz("abc",
        "foo", "bar", z: "barz",
                      ^^^^^^^^^ Each argument in a multi-line method call must start on a separate line.
               ^^^^^ Each argument in a multi-line method call must start on a separate line.
        x: "baz"
        )
      RUBY

      expect_correction(<<~RUBY)
        taz("abc",
        "foo",\s
        "bar",\s
        z: "barz",
        x: "baz"
        )
      RUBY
    end
  end

  context 'when argument starts on same line but ends on different line' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        taz("abc", {
                   ^ Each argument in a multi-line method call must start on a separate line.
          foo: "edf",
        })
      RUBY

      expect_correction(<<~RUBY)
        taz("abc",\s
        {
          foo: "edf",
        })
      RUBY
    end
  end

  context 'when second argument starts on same line as end of first' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        taz({
          foo: "edf",
        }, "abc")
           ^^^^^ Each argument in a multi-line method call must start on a separate line.
      RUBY

      expect_correction(<<~RUBY)
        taz({
          foo: "edf",
        },\s
        "abc")
      RUBY
    end
  end
end
