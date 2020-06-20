# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Layout::SpaceAroundMethodCallOperator do
  subject(:rule) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  shared_examples 'offense' do |name, code, offense, correction|
    it "registers an offense when #{name}" do
      expect_offense(offense)
    end

    it "autocorrects offense when #{name}" do
      corrected = autocorrect_source(code)

      expect(corrected).to eq(correction)
    end
  end

  context 'dot operator' do
    include_examples 'offense', 'space after method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo. bar
    CODE
      foo. bar
          ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar
    CORRECTION

    include_examples 'offense', 'space before method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo .bar
    CODE
      foo .bar
         ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar
    CORRECTION

    include_examples 'offense', 'spaces before method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo  .bar
    CODE
      foo  .bar
         ^^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar
    CORRECTION

    include_examples 'offense', 'spaces after method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo.  bar
    CODE
      foo.  bar
          ^^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar
    CORRECTION

    include_examples 'offense', 'spaces around method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo . bar
    CODE
      foo . bar
           ^ Avoid using spaces around a method call operator.
         ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar
    CORRECTION

    context 'when multi line method call' do
      include_examples 'offense', 'space before method call',
                       <<-CODE, <<-OFFENSE, <<-CORRECTION
        foo
          . bar
      CODE
        foo
          . bar
           ^ Avoid using spaces around a method call operator.
      OFFENSE
        foo
          .bar
      CORRECTION

      include_examples 'offense', 'space before method call in suffix chaining',
                       <<-CODE, <<-OFFENSE, <<-CORRECTION
        foo .
          bar
      CODE
        foo .
           ^ Avoid using spaces around a method call operator.
            bar
      OFFENSE
        foo.
          bar
      CORRECTION

      it 'does not register an offense when no space after the `.`' do
        expect_no_offenses(<<~RUBY)
          foo
            .bar
        RUBY
      end
    end

    it 'does not register an offense when no space around method call' do
      expect_no_offenses(<<~RUBY)
        'foo'.bar
      RUBY
    end

    include_examples 'offense', 'space after last method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo.bar. buzz
    CODE
      foo.bar. buzz
              ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar.buzz
    CORRECTION

    include_examples 'offense', 'space after first method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo. bar.buzz
    CODE
      foo. bar.buzz
          ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar.buzz
    CORRECTION

    include_examples 'offense', 'space before first method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo .bar.buzz
    CODE
      foo .bar.buzz
         ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar.buzz
    CORRECTION

    include_examples 'offense', 'space before last method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo.bar .buzz
    CODE
      foo.bar .buzz
             ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar.buzz
    CORRECTION

    include_examples 'offense',
                     'space around intermediate method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo.bar .buzz.bat
    CODE
      foo.bar .buzz.bat
             ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar.buzz.bat
    CORRECTION

    include_examples 'offense', 'space around multiple method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo. bar. buzz.bat
    CODE
      foo. bar. buzz.bat
               ^ Avoid using spaces around a method call operator.
          ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo.bar.buzz.bat
    CORRECTION

    it 'does not register an offense when no space around any `.` operators' do
      expect_no_offenses(<<~RUBY)
        foo.bar.buzz
      RUBY
    end

    context 'when there is a space between `.` operator and a comment' do
      it 'does not register an offense when there is not a space before `.`' do
        expect_no_offenses(<<~RUBY)
          foo. # comment
            bar.baz
        RUBY
      end

      it 'registers an offense when there is a space before `.`' do
        expect_offense(<<~RUBY)
          foo . # comment
             ^ Avoid using spaces around a method call operator.
            bar.baz
        RUBY

        expect_correction(<<~RUBY)
          foo. # comment
            bar.baz
        RUBY
      end
    end
  end

  context 'safe navigation operator' do
    include_examples 'offense', 'space after method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo&. bar
    CODE
      foo&. bar
           ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar
    CORRECTION

    include_examples 'offense', 'space before method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo &.bar
    CODE
      foo &.bar
         ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar
    CORRECTION

    include_examples 'offense', 'spaces before method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo  &.bar
    CODE
      foo  &.bar
         ^^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar
    CORRECTION

    include_examples 'offense', 'spaces after method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo&.  bar
    CODE
      foo&.  bar
           ^^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar
    CORRECTION

    include_examples 'offense', 'spaces around method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo &. bar
    CODE
      foo &. bar
            ^ Avoid using spaces around a method call operator.
         ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar
    CORRECTION

    context 'when multi line method call' do
      include_examples 'offense', 'space before method call',
                       <<-CODE, <<-OFFENSE, <<-CORRECTION
        foo
          &. bar
      CODE
        foo
          &. bar
            ^ Avoid using spaces around a method call operator.
      OFFENSE
        foo
          &.bar
      CORRECTION

      include_examples 'offense', 'space before method call in suffix chaining',
                       <<-CODE, <<-OFFENSE, <<-CORRECTION
        foo &.
          bar
      CODE
        foo &.
           ^ Avoid using spaces around a method call operator.
            bar
      OFFENSE
        foo&.
          bar
      CORRECTION

      it 'does not register an offense when no space after the `&.`' do
        expect_no_offenses(<<~RUBY)
          foo
            &.bar
        RUBY
      end
    end

    it 'does not register an offense when no space around method call' do
      expect_no_offenses(<<~RUBY)
        foo&.bar
      RUBY
    end

    include_examples 'offense', 'space after last method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo&.bar&. buzz
    CODE
      foo&.bar&. buzz
                ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar&.buzz
    CORRECTION

    include_examples 'offense', 'space after first method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo&. bar&.buzz
    CODE
      foo&. bar&.buzz
           ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar&.buzz
    CORRECTION

    include_examples 'offense', 'space before first method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo &.bar&.buzz
    CODE
      foo &.bar&.buzz
         ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar&.buzz
    CORRECTION

    include_examples 'offense', 'space before last method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo&.bar &.buzz
    CODE
      foo&.bar &.buzz
              ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar&.buzz
    CORRECTION

    include_examples 'offense',
                     'space around intermediate method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo&.bar &.buzz&.bat
    CODE
      foo&.bar &.buzz&.bat
              ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar&.buzz&.bat
    CORRECTION

    include_examples 'offense', 'space around multiple method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      foo&. bar&. buzz&.bat
    CODE
      foo&. bar&. buzz&.bat
                 ^ Avoid using spaces around a method call operator.
           ^ Avoid using spaces around a method call operator.
    OFFENSE
      foo&.bar&.buzz&.bat
    CORRECTION

    it 'does not register an offense when no space around any `.` operators' do
      expect_no_offenses(<<~RUBY)
        foo&.bar&.buzz
      RUBY
    end
  end

  context ':: operator' do
    include_examples 'offense', 'space after method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      RuboCop:: Rule
    CODE
      RuboCop:: Rule
               ^ Avoid using spaces around a method call operator.
    OFFENSE
      RuboCop::Rule
    CORRECTION

    include_examples 'offense', 'spaces after method call',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      RuboCop::  Rule
    CODE
      RuboCop::  Rule
               ^^ Avoid using spaces around a method call operator.
    OFFENSE
      RuboCop::Rule
    CORRECTION

    context 'when multi line method call' do
      include_examples 'offense', 'space before method call',
                       <<-CODE, <<-OFFENSE, <<-CORRECTION
        RuboCop
          :: Rule
      CODE
        RuboCop
          :: Rule
            ^ Avoid using spaces around a method call operator.
      OFFENSE
        RuboCop
          ::Rule
      CORRECTION

      it 'does not register an offense when no space after the `::`' do
        expect_no_offenses(<<~RUBY)
          RuboCop
            ::Rule
        RUBY
      end
    end

    it 'does not register an offense when no space around method call' do
      expect_no_offenses(<<~RUBY)
        RuboCop::Rule
      RUBY
    end

    include_examples 'offense', 'space after last method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      RuboCop::Rule:: Rule
    CODE
      RuboCop::Rule:: Rule
                    ^ Avoid using spaces around a method call operator.
    OFFENSE
      RuboCop::Rule::Rule
    CORRECTION

    include_examples 'offense',
                     'space around intermediate method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      RuboCop::Rule:: Rule::Rule
    CODE
      RuboCop::Rule:: Rule::Rule
                    ^ Avoid using spaces around a method call operator.
    OFFENSE
      RuboCop::Rule::Rule::Rule
    CORRECTION

    include_examples 'offense', 'space around multiple method call operator',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      :: RuboCop:: Rule:: Rule::Rule
    CODE
      :: RuboCop:: Rule:: Rule::Rule
                        ^ Avoid using spaces around a method call operator.
                  ^ Avoid using spaces around a method call operator.
        ^ Avoid using spaces around a method call operator.
    OFFENSE
      ::RuboCop::Rule::Rule::Rule
    CORRECTION

    include_examples 'offense', 'space after first operator with assignment',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      klass = :: RuboCop::Rule
    CODE
      klass = :: RuboCop::Rule
                ^ Avoid using spaces around a method call operator.
    OFFENSE
      klass = ::RuboCop::Rule
    CORRECTION

    it 'does not register an offense when no space around any `.` operators' do
      expect_no_offenses(<<~RUBY)
        RuboCop::Rule::Rule
      RUBY
    end

    it 'does not register an offense if no space before `::`
      operator with assignment' do
      expect_no_offenses(<<~RUBY)
        klass = ::RuboCop::Rule
      RUBY
    end

    it 'does not register an offense if no space before `::`
      operator with inheritance' do
      expect_no_offenses(<<~RUBY)
        class Test <  ::RuboCop::Rule
        end
      RUBY
    end

    it 'does not register an offense if no space with
      conditionals' do
      expect_no_offenses(<<~RUBY)
        ::RuboCop::Rule || ::RuboCop
      RUBY
    end

    include_examples 'offense', 'multiple spaces with assignment',
                     <<-CODE, <<-OFFENSE, <<-CORRECTION
      :: RuboCop:: Rule || :: RuboCop
    CODE
      :: RuboCop:: Rule || :: RuboCop
                             ^ Avoid using spaces around a method call operator.
                  ^ Avoid using spaces around a method call operator.
        ^ Avoid using spaces around a method call operator.
    OFFENSE
      ::RuboCop::Rule || ::RuboCop
    CORRECTION
  end

  it 'does not register an offense when no method call operator' do
    expect_no_offenses(<<~RUBY)
      'foo' + 'bar'
    RUBY
  end
end
