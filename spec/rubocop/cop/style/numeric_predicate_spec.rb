# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::NumericPredicate, :config do
  before do
    inspect_source(source)
  end

  shared_examples(
    'code with offense'
  ) do |code, options|
    context "when checking #{code}" do
      let(:source) { code }
      let(:use) { options[:use] || options[:expected] }
      let(:instead_of) { options[:instead_of] || code }

      let(:message) { "Use `#{use}` instead of `#{instead_of}`." }

      it 'registers an offense' do
        expect(rule.offenses.size).to eq(1)
        expect(rule.messages).to eq([message])
      end

      if (expected = options[:expected])
        it 'auto-corrects' do
          expect(autocorrect_source(code)).to eq(expected)
        end
      else
        it 'does not auto-correct' do
          expect(autocorrect_source(code)).to eq(code)
        end
      end
    end
  end

  shared_examples 'code without offense' do |code|
    let(:source) { code }

    it 'does not register an offense' do
      expect(rule.offenses.empty?).to be(true)
    end
  end

  context 'when configured to enforce numeric predicate methods' do
    let(:rule_config) do
      { 'EnforcedStyle' => 'predicate', 'AutoCorrect' => true }
    end

    context 'when checking if a number is zero' do
      it_behaves_like 'code with offense',
                      'number == 0',
                      expected: 'number.zero?'

      it_behaves_like 'code with offense',
                      '0 == number',
                      expected: 'number.zero?'

      context 'with a complex expression' do
        it_behaves_like 'code with offense',
                        'foo - 1 == 0',
                        expected: '(foo - 1).zero?'

        it_behaves_like 'code with offense',
                        '0 == foo - 1',
                        expected: '(foo - 1).zero?'
      end

      context 'when comparing against a global variable' do
        it_behaves_like 'code without offense',
                        '$CHILD_STATUS == 0'

        it_behaves_like 'code without offense',
                        '0 == $CHILD_STATUS'
      end

      context 'when comparing against a method argument variable' do
        it_behaves_like 'code with offense',
                        'def m(foo); foo == 0; end',
                        expected: 'def m(foo); foo.zero?; end',
                        use: 'foo.zero?',
                        instead_of: 'foo == 0'

        it_behaves_like 'code with offense',
                        'def m(foo); foo - 1 == 0; end',
                        expected: 'def m(foo); (foo - 1).zero?; end',
                        use: '(foo - 1).zero?',
                        instead_of: 'foo - 1 == 0'
      end
    end

    context 'with checking if a number is not zero' do
      it_behaves_like 'code without offense',
                      'number != 0'

      it_behaves_like 'code without offense',
                      '0 != number'

      context 'with a complex expression' do
        it_behaves_like 'code without offense',
                        'foo - 1 != 0'

        it_behaves_like 'code without offense',
                        '0 != foo - 1'
      end

      context 'when comparing against a global variable' do
        it_behaves_like 'code without offense',
                        '$CHILD_STATUS != 0'

        it_behaves_like 'code without offense',
                        '0 != $CHILD_STATUS'
      end
    end

    context 'when checking if a number is positive' do
      it_behaves_like 'code with offense',
                      'number > 0',
                      expected: 'number.positive?'

      it_behaves_like 'code with offense',
                      '0 < number',
                      expected: 'number.positive?'

      context 'with a complex expression' do
        it_behaves_like 'code with offense',
                        'foo - 1 > 0',
                        expected: '(foo - 1).positive?'

        it_behaves_like 'code with offense',
                        '0 < foo - 1',
                        expected: '(foo - 1).positive?'
      end
    end

    context 'when checking if a number is negative' do
      it_behaves_like 'code with offense',
                      'number < 0',
                      expected: 'number.negative?'

      it_behaves_like 'code with offense',
                      '0 > number',
                      expected: 'number.negative?'

      context 'with a complex expression' do
        it_behaves_like 'code with offense',
                        'foo - 1 < 0',
                        expected: '(foo - 1).negative?'

        it_behaves_like 'code with offense',
                        '0 > foo - 1',
                        expected: '(foo - 1).negative?'
      end
    end
  end

  context 'when configured to enforce numeric comparison methods' do
    let(:rule_config) do
      { 'EnforcedStyle' => 'comparison', 'AutoCorrect' => true }
    end

    context 'when checking if a number is zero' do
      it_behaves_like 'code with offense',
                      'number.zero?',
                      expected: 'number == 0'
    end

    context 'with checking if a number is not zero' do
      it_behaves_like 'code without offense',
                      'number.nonzero?'
    end

    context 'when checking if a number is positive' do
      it_behaves_like 'code with offense',
                      'number.positive?',
                      expected: 'number > 0'
    end

    context 'when checking if a number is negative' do
      it_behaves_like 'code with offense',
                      'number.negative?',
                      expected: 'number < 0'
    end
  end

  context 'when there are ignored methods' do
    let(:rule_config) do
      {
        'EnforcedStyle' => 'predicate',
        'AutoCorrect' => true,
        'IgnoredMethods' => %w[where]
      }
    end

    context 'simple method call' do
      context '`EnforcedStyle` is `predicate`' do
        let(:rule_config) do
          {
            'EnforcedStyle' => 'predicate',
            'IgnoredMethods' => %w[==]
          }
        end

        context 'when checking if a number is zero' do
          it_behaves_like 'code without offense', <<~RUBY
            if number == 0
              puts 'hello'
            end
          RUBY
        end
      end

      context '`EnforcedStyle` is `comparison`' do
        let(:rule_config) do
          {
            'EnforcedStyle' => 'comparison',
            'IgnoredMethods' => %w[zero?]
          }
        end

        context 'when checking if a number is zero' do
          it_behaves_like 'code without offense', <<~RUBY
            if number.zero?
              puts 'hello'
            end
          RUBY
        end
      end
    end

    context 'in argument' do
      context 'ignored method' do
        context 'when checking if a number is positive' do
          it_behaves_like 'code without offense', 'where(Sequel[:number] > 0)'
        end

        context 'when checking if a number is negative' do
          it_behaves_like 'code without offense', 'where(Sequel[:number] < 0)'
        end
      end

      context 'not ignored method' do
        context 'when checking if a number is positive' do
          it_behaves_like 'code with offense',
                          'exclude(number > 0)',
                          expected: 'exclude(number.positive?)',
                          use: 'number.positive?',
                          instead_of: 'number > 0'
        end

        context 'when checking if a number is negative' do
          it_behaves_like 'code with offense',
                          'exclude(number < 0)',
                          expected: 'exclude(number.negative?)',
                          use: 'number.negative?',
                          instead_of: 'number < 0'
        end
      end
    end

    context 'in block' do
      context 'ignored method' do
        context 'when checking if a number is positive' do
          it_behaves_like 'code without offense', 'where { table[number] > 0 }'
        end

        context 'when checking if a number is negative' do
          it_behaves_like 'code without offense', 'where { table[number] < 0 }'
        end
      end

      context 'not ignored method' do
        context 'when checking if a number is positive' do
          it_behaves_like 'code with offense',
                          'exclude { number > 0 }',
                          expected: 'exclude { number.positive? }',
                          use: 'number.positive?',
                          instead_of: 'number > 0'
        end

        context 'when checking if a number is negative' do
          it_behaves_like 'code with offense',
                          'exclude { number < 0 }',
                          expected: 'exclude { number.negative? }',
                          use: 'number.negative?',
                          instead_of: 'number < 0'
        end
      end
    end
  end
end
