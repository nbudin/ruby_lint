# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::CollectionMethods, :config do
  rule_config = {
    'PreferredMethods' => {
      'collect' => 'map',
      'inject' => 'reduce',
      'detect' => 'find',
      'find_all' => 'select',
      'member?' => 'include?'
    }
  }

  subject(:rule) { described_class.new(config) }

  let(:rule_config) { rule_config }

  rule_config['PreferredMethods'].each do |method, preferred_method|
    it "registers an offense for #{method} with block" do
      inspect_source("[1, 2, 3].#{method} { |e| e + 1 }")
      expect(rule.offenses.size).to eq(1)
      expect(cop.messages)
        .to eq(["Prefer `#{preferred_method}` over `#{method}`."])
    end

    it "registers an offense for #{method} with proc param" do
      inspect_source("[1, 2, 3].#{method}(&:test)")
      expect(rule.offenses.size).to eq(1)
      expect(cop.messages)
        .to eq(["Prefer `#{preferred_method}` over `#{method}`."])
    end

    it "accepts #{method} with more than 1 param" do
      expect_no_offenses(<<~RUBY)
        [1, 2, 3].#{method}(other, &:test)
      RUBY
    end

    it "accepts #{method} without a block" do
      expect_no_offenses(<<~RUBY)
        [1, 2, 3].#{method}
      RUBY
    end

    it 'auto-corrects to preferred method' do
      new_source = autocorrect_source('some.collect(&:test)')
      expect(new_source).to eq('some.map(&:test)')
    end
  end
end
