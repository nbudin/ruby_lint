# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::WhenThen do
  subject(:rule) { described_class.new }

  it 'registers an offense for when x;' do
    expect_offense(<<~RUBY)
      case a
      when b; c
            ^ Do not use `when x;`. Use `when x then` instead.
      end
    RUBY
  end

  it 'accepts when x then' do
    expect_no_offenses(<<~RUBY)
      case a
      when b then c
      end
    RUBY
  end

  it 'accepts ; separating statements in the body of when' do
    expect_no_offenses(<<~RUBY)
      case a
      when b then c; d
      end

      case e
      when f
        g; h
      end
    RUBY
  end

  it 'auto-corrects "when x;" with "when x then"' do
    new_source = autocorrect_source(<<~RUBY)
      case a
      when b; c
      end
    RUBY
    expect(new_source).to eq(<<~RUBY)
      case a
      when b then c
      end
    RUBY
  end

  # Regression: https://github.com/rubocop-hq/rubocop/issues/3868
  context 'when inspecting a case statement with an empty branch' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        case value
        when cond1
        end
      RUBY
    end
  end
end
