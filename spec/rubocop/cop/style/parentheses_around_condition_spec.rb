# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::ParenthesesAroundCondition, :config do
  let(:rule_config) { { 'AllowSafeAssignment' => true } }

  it 'registers an offense for parentheses around condition' do
    expect_offense(<<~RUBY)
      if (x > 10)
         ^^^^^^^^ Don't use parentheses around the condition of an `if`.
      elsif (x < 3)
            ^^^^^^^ Don't use parentheses around the condition of an `elsif`.
      end
      unless (x > 10)
             ^^^^^^^^ Don't use parentheses around the condition of an `unless`.
      end
      while (x > 10)
            ^^^^^^^^ Don't use parentheses around the condition of a `while`.
      end
      until (x > 10)
            ^^^^^^^^ Don't use parentheses around the condition of an `until`.
      end
      x += 1 if (x < 10)
                ^^^^^^^^ Don't use parentheses around the condition of an `if`.
      x += 1 unless (x < 10)
                    ^^^^^^^^ Don't use parentheses around the condition of an `unless`.
      x += 1 until (x < 10)
                   ^^^^^^^^ Don't use parentheses around the condition of an `until`.
      x += 1 while (x < 10)
                   ^^^^^^^^ Don't use parentheses around the condition of a `while`.
    RUBY
  end

  it 'accepts parentheses if there is no space between the keyword and (.' do
    expect_no_offenses(<<~RUBY)
      if(x > 5) then something end
      do_something until(x > 5)
    RUBY
  end

  it 'auto-corrects parentheses around condition' do
    corrected = autocorrect_source(<<~RUBY)
      if (x > 10)
      elsif (x < 3)
      end
      unless (x > 10)
      end
      while (x > 10)
      end
      until (x > 10)
      end
      x += 1 if (x < 10)
      x += 1 unless (x < 10)
      x += 1 while (x < 10)
      x += 1 until (x < 10)
    RUBY
    expect(corrected).to eq <<~RUBY
      if x > 10
      elsif x < 3
      end
      unless x > 10
      end
      while x > 10
      end
      until x > 10
      end
      x += 1 if x < 10
      x += 1 unless x < 10
      x += 1 while x < 10
      x += 1 until x < 10
    RUBY
  end

  it 'accepts condition without parentheses' do
    expect_no_offenses(<<~RUBY)
      if x > 10
      end
      unless x > 10
      end
      while x > 10
      end
      until x > 10
      end
      x += 1 if x < 10
      x += 1 unless x < 10
      x += 1 while x < 10
      x += 1 until x < 10
    RUBY
  end

  it 'accepts parentheses around condition in a ternary' do
    expect_no_offenses('(a == 0) ? b : a')
  end

  it 'is not confused by leading parentheses in subexpression' do
    expect_no_offenses('(a > b) && other ? one : two')
  end

  it 'is not confused by unbalanced parentheses' do
    expect_no_offenses(<<~RUBY)
      if (a + b).c()
      end
    RUBY
  end

  %w[rescue if unless while until].each do |op|
    it "allows parens if the condition node is a modifier #{op} op" do
      expect_no_offenses(<<~RUBY)
        if (something #{op} top)
        end
      RUBY
    end
  end

  it 'does not blow up when the condition is a ternary op' do
    expect_offense(<<~RUBY)
      x if (a ? b : c)
           ^^^^^^^^^^^ Don't use parentheses around the condition of an `if`.
    RUBY
  end

  it 'does not blow up for empty if condition' do
    expect_no_offenses(<<~RUBY)
      if ()
      end
    RUBY
  end

  it 'does not blow up for empty unless condition' do
    expect_no_offenses(<<~RUBY)
      unless ()
      end
    RUBY
  end

  context 'safe assignment is allowed' do
    it 'accepts variable assignment in condition surrounded with parentheses' do
      expect_no_offenses(<<~RUBY)
        if (test = 10)
        end
      RUBY
    end

    it 'accepts element assignment in condition surrounded with parentheses' do
      expect_no_offenses(<<~RUBY)
        if (test[0] = 10)
        end
      RUBY
    end

    it 'accepts setter in condition surrounded with parentheses' do
      expect_no_offenses(<<~RUBY)
        if (self.test = 10)
        end
      RUBY
    end
  end

  context 'safe assignment is not allowed' do
    let(:rule_config) { { 'AllowSafeAssignment' => false } }

    it 'does not accept variable assignment in condition surrounded with ' \
       'parentheses' do
      expect_offense(<<~RUBY)
        if (test = 10)
           ^^^^^^^^^^^ Don't use parentheses around the condition of an `if`.
        end
      RUBY
    end

    it 'does not accept element assignment in condition surrounded with ' \
       'parentheses' do
      expect_offense(<<~RUBY)
        if (test[0] = 10)
           ^^^^^^^^^^^^^^ Don't use parentheses around the condition of an `if`.
        end
      RUBY
    end
  end

  context 'parentheses in multiline conditions are allowed' do
    let(:rule_config) { { 'AllowInMultilineConditions' => true } }

    it 'accepts parentheses around multiline condition' do
      expect_no_offenses(<<~RUBY)
        if (
          x > 3 &&
          x < 10
        )
          return true
        end
      RUBY
    end

    it 'registers an offense for parentheses in single line condition' do
      expect_offense(<<~RUBY)
        if (x > 3 && x < 10)
           ^^^^^^^^^^^^^^^^^ Don't use parentheses around the condition of an `if`.
          return true
        end
      RUBY
    end
  end

  context 'parentheses in multiline conditions are not allowed' do
    let(:rule_config) { { 'AllowInMultilineConditions' => false } }

    it 'registers an offense for parentheses around multiline condition' do
      expect_offense(<<~RUBY)
        if (
           ^ Don't use parentheses around the condition of an `if`.
          x > 3 &&
          x < 10
        )
          return true
        end
      RUBY
    end
  end
end
