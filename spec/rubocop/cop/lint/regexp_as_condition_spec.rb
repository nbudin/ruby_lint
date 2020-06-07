# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Lint::RegexpAsCondition do
  subject(:rule) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  it 'registers an offense for a regexp literal in `if` condition' do
    expect_offense(<<~RUBY)
      if /foo/
         ^^^^^ Do not use regexp literal as a condition. The regexp literal matches `$_` implicitly.
      end
    RUBY
  end

  it 'does not register an offense for a regexp literal outside conditions' do
    expect_no_offenses(<<~RUBY)
      /foo/
    RUBY
  end

  it 'does not register an offense for a regexp literal with `=~` operator' do
    expect_no_offenses(<<~RUBY)
      if /foo/ =~ str
      end
    RUBY
  end
end
