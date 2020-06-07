# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Style::PerlBackrefs do
  subject(:cop) { described_class.new }

  it 'registers an offense for $1' do
    expect_offense(<<~RUBY)
      puts $1
           ^^ Avoid the use of Perl-style backrefs.
    RUBY
  end

  it 'auto-corrects $1 to Regexp.last_match(1)' do
    new_source = autocorrect_source('$1')
    expect(new_source).to eq('Regexp.last_match(1)')
  end

  it 'auto-corrects #$1 to #{Regexp.last_match(1)}' do
    new_source = autocorrect_source('"#$1"')
    expect(new_source).to eq('"#{Regexp.last_match(1)}"')
  end
end
