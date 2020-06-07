# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Style::GlobalVars, :config do
  cop_config = {
    'AllowedVariables' => ['$allowed']
  }

  subject(:cop) { described_class.new(config) }

  let(:cop_config) { cop_config }

  it 'registers an offense for $custom' do
    expect_offense(<<~RUBY)
      puts $custom
           ^^^^^^^ Do not introduce global variables.
    RUBY
  end

  it 'allows user permitted variables' do
    expect_no_offenses('puts $allowed')
  end

  described_class::BUILT_IN_VARS.each do |var|
    it "does not register an offense for built-in variable #{var}" do
      expect_no_offenses(<<~RUBY)
        puts #{var}
      RUBY
    end
  end

  it 'does not register an offense for backrefs like $1' do
    expect_no_offenses('puts $1')
  end
end
