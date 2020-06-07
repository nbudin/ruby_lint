# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Lint::NonLocalExitFromIterator do
  subject(:rule) { described_class.new }

  context 'inspection' do
    before do
      inspect_source(source)
    end

    let(:message) do
      'Non-local exit from iterator, without return value. ' \
        '`next`, `break`, `Array#find`, `Array#any?`, etc. is preferred.'
    end

    shared_examples_for 'offense detector' do
      it 'registers an offense' do
        expect(rule.offenses.size).to eq(1)
        expect(rule.offenses.first.message).to eq(message)
        expect(rule.offenses.first.severity.name).to eq(:warning)
        expect(rule.highlights).to eq(['return'])
      end
    end

    context 'when block is followed by method chain' do
      context 'and has single argument' do
        let(:source) { <<-RUBY }
          items.each do |item|
            return if item.stock == 0
            item.update!(foobar: true)
          end
        RUBY

        it_behaves_like('offense detector')
        it { expect(rule.offenses.first.line).to eq(2) }
      end

      context 'and has multiple arguments' do
        let(:source) { <<-RUBY }
          items.each_with_index do |item, i|
            return if item.stock == 0
            item.update!(foobar: true)
          end
        RUBY

        it_behaves_like('offense detector')
        it { expect(rule.offenses.first.line).to eq(2) }
      end

      context 'and has no argument' do
        let(:source) { <<-RUBY }
          item.with_lock do
            return if item.stock == 0
            item.update!(foobar: true)
          end
        RUBY

        it { expect(rule.offenses.empty?).to be(true) }
      end
    end

    context 'when block is not followed by method chain' do
      let(:source) { <<-RUBY }
        transaction do
          return unless update_necessary?
          find_each do |item|
            return if item.stock == 0 # false-negative...
            item.update!(foobar: true)
          end
        end
      RUBY

      it { expect(rule.offenses.empty?).to be(true) }
    end

    context 'when block is lambda' do
      let(:source) { <<-RUBY }
        items.each(lambda do |item|
          return if item.stock == 0
          item.update!(foobar: true)
        end)
        items.each -> (item) {
          return if item.stock == 0
          item.update!(foobar: true)
        }
      RUBY

      it { expect(rule.offenses.empty?).to be(true) }
    end

    context 'when lambda is inside of block followed by method chain' do
      let(:source) { <<-RUBY }
        RSpec.configure do |config|
          # some configuration

          if Gem.loaded_specs["paper_trail"].version < Gem::Version.new("4.0.0")
            current_behavior = ActiveSupport::Deprecation.behavior
            ActiveSupport::Deprecation.behavior = lambda do |message, callstack|
              return if message =~ /foobar/
              Array.wrap(current_behavior).each do |behavior|
                behavior.call(message, callstack)
              end
            end

            # more configuration
          end
        end
      RUBY

      it { expect(rule.offenses.empty?).to be(true) }
    end

    context 'when block in middle of nest is followed by method chain' do
      let(:source) { <<-RUBY }
        transaction do
          return unless update_necessary?
          items.each do |item|
            return if item.nil?
            item.with_lock do
              return if item.stock == 0
              item.very_complicated_update_operation!
            end
          end
        end
      RUBY

      it 'registers offenses' do
        expect(rule.offenses.size).to eq(2)
        expect(rule.offenses[0].message).to eq(message)
        expect(rule.offenses[0].severity.name).to eq(:warning)
        expect(rule.offenses[0].line).to eq(4)
        expect(rule.offenses[1].message).to eq(message)
        expect(rule.offenses[1].severity.name).to eq(:warning)
        expect(rule.offenses[1].line).to eq(6)
        expect(rule.highlights).to eq(%w[return return])
      end
    end

    context 'when return with value' do
      let(:source) { <<-RUBY }
        def find_first_sold_out_item(items)
          items.each do |item|
            return item if item.stock == 0
            item.foobar!
          end
        end
      RUBY

      it { expect(rule.offenses.empty?).to be(true) }
    end

    context 'when the message is define_method' do
      let(:source) { <<-RUBY }
        [:method_one, :method_two].each do |method_name|
          define_method(method_name) do
            return if predicate?
          end
        end
      RUBY

      it { expect(rule.offenses.empty?).to be(true) }
    end

    context 'when the message is define_singleton_method' do
      let(:source) { <<-RUBY }
        str = 'foo'
        str.define_singleton_method :bar do |baz|
          return unless baz
          replace baz
        end
      RUBY

      it { expect(rule.offenses.empty?).to be(true) }
    end

    context 'when the return is within a nested method definition' do
      context 'with an instance method definition' do
        let(:source) { <<-RUBY }
          Foo.configure do |c|
            def bar
              return if baz?
            end
          end
        RUBY

        it { expect(rule.offenses.empty?).to be(true) }
      end

      context 'with a class method definition' do
        let(:source) { <<-RUBY }
          Foo.configure do |c|
            def self.bar
              return if baz?
            end
          end
        RUBY

        it { expect(rule.offenses.empty?).to be(true) }
      end
    end
  end
end
