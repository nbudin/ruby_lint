# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Layout::MultilineArrayBraceLayout, :config do
  let(:rule_config) { { 'EnforcedStyle' => 'symmetrical' } }

  it 'ignores implicit arrays' do
    expect_no_offenses(<<~RUBY)
      foo = a,
      b
    RUBY
  end

  it 'ignores single-line arrays' do
    expect_no_offenses('[a, b, c]')
  end

  it 'ignores empty arrays' do
    expect_no_offenses('[]')
  end

  it_behaves_like 'multiline literal brace layout' do
    let(:open) { '[' }
    let(:close) { ']' }
  end

  it_behaves_like 'multiline literal brace layout method argument' do
    let(:open) { '[' }
    let(:close) { ']' }
    let(:a) { 'a: 1' }
    let(:b) { 'b: 2' }
  end

  it_behaves_like 'multiline literal brace layout trailing comma' do
    let(:open) { '[' }
    let(:close) { ']' }
  end
end
