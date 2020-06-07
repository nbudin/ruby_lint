# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::ColonMethodCall do
  subject(:rule) { described_class.new }

  it 'registers an offense for instance method call' do
    expect_offense(<<~RUBY)
      test::method_name
          ^^ Do not use `::` for method calls.
    RUBY
  end

  it 'registers an offense for instance method call with arg' do
    expect_offense(<<~RUBY)
      test::method_name(arg)
          ^^ Do not use `::` for method calls.
    RUBY
  end

  it 'registers an offense for class method call' do
    expect_offense(<<~RUBY)
      Class::method_name
           ^^ Do not use `::` for method calls.
    RUBY
  end

  it 'registers an offense for class method call with arg' do
    expect_offense(<<~RUBY)
      Class::method_name(arg, arg2)
           ^^ Do not use `::` for method calls.
    RUBY
  end

  it 'does not register an offense for constant access' do
    expect_no_offenses('Tip::Top::SOME_CONST')
  end

  it 'does not register an offense for nested class' do
    expect_no_offenses('Tip::Top.some_method')
  end

  it 'does not register an offense for op methods' do
    expect_no_offenses('Tip::Top.some_method[3]')
  end

  it 'does not register an offense when for constructor methods' do
    expect_no_offenses('Tip::Top(some_arg)')
  end

  it 'does not register an offense for Java static types' do
    expect_no_offenses('Java::int')
  end

  it 'does not register an offense for Java package namespaces' do
    expect_no_offenses('Java::com')
  end

  it 'auto-corrects "::" with "."' do
    new_source = autocorrect_source('test::method')
    expect(new_source).to eq('test.method')
  end
end
