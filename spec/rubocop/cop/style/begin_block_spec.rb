# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Style::BeginBlock do
  subject(:cop) { described_class.new }

  it 'reports an offense for a BEGIN block' do
    expect_offense(<<~RUBY)
      BEGIN { test }
      ^^^^^ Avoid the use of `BEGIN` blocks.
    RUBY
  end
end
