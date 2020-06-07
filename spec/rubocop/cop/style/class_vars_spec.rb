# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Style::ClassVars do
  subject(:cop) { described_class.new }

  it 'registers an offense for class variable declaration' do
    expect_offense(<<~RUBY)
      class TestClass; @@test = 10; end
                       ^^^^^^ Replace class var @@test with a class instance var.
    RUBY
  end

  it 'does not register an offense for class variable usage' do
    expect_no_offenses('@@test.test(20)')
  end
end
