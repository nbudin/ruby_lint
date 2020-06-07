# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Style::IfInsideElse, :config do
  let(:cop_config) do
    { 'AllowIfModifier' => false }
  end

  it 'catches an if node nested inside an else' do
    expect_offense(<<~RUBY)
      if a
        blah
      else
        if b
        ^^ Convert `if` nested inside `else` to `elsif`.
          foo
        end
      end
    RUBY
  end

  it 'catches an if..else nested inside an else' do
    expect_offense(<<~RUBY)
      if a
        blah
      else
        if b
        ^^ Convert `if` nested inside `else` to `elsif`.
          foo
        else
          bar
        end
      end
    RUBY
  end

  context 'when AllowIfModifier is false' do
    it 'catches a modifier if nested inside an else' do
      expect_offense(<<~RUBY)
        if a
          blah
        else
          foo if b
              ^^ Convert `if` nested inside `else` to `elsif`.
        end
      RUBY
    end
  end

  context 'when AllowIfModifier is true' do
    let(:cop_config) do
      { 'AllowIfModifier' => true }
    end

    it 'accepts a modifier if nested inside an else' do
      expect_no_offenses(<<~RUBY)
        if a
          blah
        else
          foo if b
        end
      RUBY
    end
  end

  it "isn't offended if there is a statement following the if node" do
    expect_no_offenses(<<~RUBY)
      if a
        blah
      else
        if b
          foo
        end
        bar
      end
    RUBY
  end

  it "isn't offended if there is a statement preceding the if node" do
    expect_no_offenses(<<~RUBY)
      if a
        blah
      else
        bar
        if b
          foo
        end
      end
    RUBY
  end

  it "isn't offended by if..elsif..else" do
    expect_no_offenses(<<~RUBY)
      if a
        blah
      elsif b
        blah
      else
        blah
      end
    RUBY
  end

  it 'ignores unless inside else' do
    expect_no_offenses(<<~RUBY)
      if a
        blah
      else
        unless b
          foo
        end
      end
    RUBY
  end

  it 'ignores if inside unless' do
    expect_no_offenses(<<~RUBY)
      unless a
        if b
          foo
        end
      end
    RUBY
  end

  it 'ignores nested ternary expressions' do
    expect_no_offenses('a ? b : c ? d : e')
  end

  it 'ignores ternary inside if..else' do
    expect_no_offenses(<<~RUBY)
      if a
        blah
      else
        a ? b : c
      end
    RUBY
  end
end
