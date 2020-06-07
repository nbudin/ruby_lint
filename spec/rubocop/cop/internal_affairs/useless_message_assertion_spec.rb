# frozen_string_literal: true

RSpec.describe RuboCop::Rule::InternalAffairs::UselessMessageAssertion do
  subject(:rule) { described_class.new }

  it 'registers an offense for specs that assert using the MSG' do
    expect_offense(<<~RUBY, 'example_spec.rb')
      it 'uses described_class::MSG to specify the expected message' do
        inspect_source(rule, 'foo')
        expect(rule.messages).to eq([described_class::MSG])
                                     ^^^^^^^^^^^^^^^^^^^^ Do not specify rule behavior using `described_class::MSG`.
      end
    RUBY
  end

  it 'registers an offense for described_class::MSG in let' do
    expect_offense(<<~RUBY, 'example_spec.rb')
      let(:msg) { described_class::MSG }
                  ^^^^^^^^^^^^^^^^^^^^ Do not specify rule behavior using `described_class::MSG`.
    RUBY
  end

  it 'does not register an offense for an assertion about the message' do
    expect_no_offenses(<<~RUBY, 'example_spec.rb')
      it 'has a good message' do
        expect(described_class::MSG).to eq('Good message.')
      end
    RUBY
  end
end
