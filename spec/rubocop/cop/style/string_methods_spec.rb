# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::StringMethods, :config do
  let(:rule_config) { { 'intern' => 'to_sym' } }

  it 'registers an offense' do
    expect_offense(<<~RUBY)
      'something'.intern
                  ^^^^^^ Prefer `to_sym` over `intern`.
    RUBY
  end

  it 'auto-corrects' do
    corrected = autocorrect_source("'something'.intern")

    expect(corrected).to eq("'something'.to_sym")
  end

  context 'when using safe navigation operator' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        something&.intern
                   ^^^^^^ Prefer `to_sym` over `intern`.
      RUBY
    end

    it 'auto-corrects' do
      corrected = autocorrect_source('something&.intern')

      expect(corrected).to eq('something&.to_sym')
    end
  end
end
