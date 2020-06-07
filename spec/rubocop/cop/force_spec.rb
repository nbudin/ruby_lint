# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Force do
  subject(:force) { described_class.new(cops) }

  let(:cops) do
    [
      instance_double(Rubocop::Rule::Rule),
      instance_double(Rubocop::Rule::Rule)
    ]
  end

  describe '.force_name' do
    it 'returns the class name without namespace' do
      expect(Rubocop::Rule::VariableForce.force_name).to eq('VariableForce')
    end
  end

  describe '#run_hook' do
    it 'invokes a hook in all cops' do
      expect(cops).to all receive(:message).with(:foo)

      force.run_hook(:message, :foo)
    end
  end
end
