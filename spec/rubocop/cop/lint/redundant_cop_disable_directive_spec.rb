# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Lint::RedundantRuleDisableDirective, :config do
  describe '.check' do
    let(:rule_options) { { auto_correct: true } }
    let(:comments) { processed_source.comments }
    let(:corrected_source) do
      RuboCop::Rule::Corrector
        .new(processed_source.buffer, rule.corrections)
        .rewrite
    end

    before do
      $stderr = StringIO.new # rubocop:disable RSpec/ExpectOutput
      rule.check(offenses, rule_disabled_line_ranges, comments)
    end

    context 'when there are no disabled lines' do
      let(:offenses) { [] }
      let(:rule_disabled_line_ranges) { {} }
      let(:source) { '' }

      it 'returns an empty array' do
        expect(rule.offenses).to eq([])
      end
    end

    context 'when there are disabled lines' do
      context 'and there are no offenses' do
        let(:offenses) { [] }

        context 'and a comment disables' do
          context 'one rule' do
            let(:source) { "# rubocop:disable Metrics/MethodLength\n" }
            let(:rule_disabled_line_ranges) do
              { 'Metrics/MethodLength' => [1..Float::INFINITY] }
            end

            it 'returns an offense' do
              expect(rule.messages)
                .to eq(['Unnecessary disabling of `Metrics/MethodLength`.'])
              expect(rule.highlights)
                .to eq(['# rubocop:disable Metrics/MethodLength'])
            end

            it 'gives the right rule name' do
              expect(rule.name).to eq('Lint/RedundantRuleDisableDirective')
            end

            it 'autocorrects' do
              expect(corrected_source).to eq('')
            end
          end

          context 'an unknown rule' do
            let(:source) { '# rubocop:disable UnknownCop' }
            let(:rule_disabled_line_ranges) do
              { 'UnknownCop' => [1..Float::INFINITY] }
            end

            it 'returns an offense' do
              expect(rule.messages)
                .to eq(['Unnecessary disabling of `UnknownCop` (unknown rule).'])
              expect(rule.highlights)
                .to eq(['# rubocop:disable UnknownCop'])
            end
          end

          context 'itself' do
            let(:source) do
              '# rubocop:disable Lint/RedundantRuleDisableDirective'
            end
            let(:rule_disabled_line_ranges) do
              { 'Lint/RedundantRuleDisableDirective' => [1..Float::INFINITY] }
            end

            it 'does not return an offense' do
              expect(rule.offenses.empty?).to be(true)
            end
          end

          context 'itself and another rule' do
            context 'disabled on the same range' do
              let(:source) do
                '# rubocop:disable Lint/RedundantRuleDisableDirective, ' \
                'Metrics/ClassLength'
              end

              let(:rule_disabled_line_ranges) do
                { 'Lint/RedundantRuleDisableDirective' => [1..Float::INFINITY],
                  'Metrics/ClassLength' => [1..Float::INFINITY] }
              end

              it 'does not return an offense' do
                expect(rule.offenses.empty?).to be(true)
              end
            end

            context 'disabled on different ranges' do
              let(:source) do
                ['# rubocop:disable Lint/RedundantRuleDisableDirective',
                 '# rubocop:disable Metrics/ClassLength'].join("\n")
              end

              let(:rule_disabled_line_ranges) do
                { 'Lint/RedundantRuleDisableDirective' => [1..Float::INFINITY],
                  'Metrics/ClassLength' => [2..Float::INFINITY] }
              end

              it 'does not return an offense' do
                expect(rule.offenses.empty?).to be(true)
              end
            end

            context 'and the other rule is disabled a second time' do
              let(:source) do
                ['# rubocop:disable Lint/RedundantRuleDisableDirective',
                 '# rubocop:disable Metrics/ClassLength',
                 '# rubocop:disable Metrics/ClassLength'].join("\n")
              end

              let(:rule_disabled_line_ranges) do
                { 'Lint/RedundantRuleDisableDirective' => [1..Float::INFINITY],
                  'Metrics/ClassLength' => [(2..3), (3..Float::INFINITY)] }
              end

              it 'does not return an offense' do
                expect(rule.offenses.empty?).to be(true)
              end
            end
          end

          context 'multiple rules' do
            let(:source) do
              '# rubocop:disable Metrics/MethodLength, Metrics/ClassLength'
            end
            let(:rule_disabled_line_ranges) do
              { 'Metrics/ClassLength' => [1..Float::INFINITY],
                'Metrics/MethodLength' => [1..Float::INFINITY] }
            end

            it 'returns an offense' do
              expect(rule.messages)
                .to eq(['Unnecessary disabling of `Metrics/ClassLength`, ' \
                        '`Metrics/MethodLength`.'])
            end
          end

          context 'multiple rules, and one of them has offenses' do
            let(:source) do
              '# rubocop:disable Metrics/MethodLength, Metrics/ClassLength, ' \
              'Lint/Debugger, Lint/AmbiguousOperator'
            end
            let(:rule_disabled_line_ranges) do
              { 'Metrics/ClassLength' => [1..Float::INFINITY],
                'Metrics/MethodLength' => [1..Float::INFINITY],
                'Lint/Debugger' => [1..Float::INFINITY],
                'Lint/AmbiguousOperator' => [1..Float::INFINITY] }
            end
            let(:offenses) do
              [
                RuboCop::Rule::Offense.new(:convention,
                                          OpenStruct.new(line: 7, column: 0),
                                          'Class has too many lines.',
                                          'Metrics/ClassLength')
              ]
            end

            it 'returns an offense' do
              expect(rule.messages)
                .to eq(['Unnecessary disabling of `Metrics/MethodLength`.',
                        'Unnecessary disabling of `Lint/Debugger`.',
                        'Unnecessary disabling of `Lint/AmbiguousOperator`.'])
              expect(rule.highlights).to eq(['Metrics/MethodLength',
                                            'Lint/Debugger',
                                            'Lint/AmbiguousOperator'])
            end

            it 'autocorrects' do
              expect(corrected_source).to eq(
                '# rubocop:disable Metrics/ClassLength'
              )
            end
          end

          context 'multiple rules, and the leftmost one has no offenses' do
            let(:source) do
              '# rubocop:disable Metrics/ClassLength, Metrics/MethodLength'
            end
            let(:rule_disabled_line_ranges) do
              { 'Metrics/ClassLength' => [1..Float::INFINITY],
                'Metrics/MethodLength' => [1..Float::INFINITY] }
            end
            let(:offenses) do
              [
                RuboCop::Rule::Offense.new(:convention,
                                          OpenStruct.new(line: 7, column: 0),
                                          'Method has too many lines.',
                                          'Metrics/MethodLength')
              ]
            end

            it 'returns an offense' do
              expect(rule.messages)
                .to eq(['Unnecessary disabling of `Metrics/ClassLength`.'])
              expect(rule.highlights).to eq(['Metrics/ClassLength'])
            end

            it 'autocorrects' do
              expect(corrected_source).to eq(
                '# rubocop:disable Metrics/MethodLength'
              )
            end
          end

          context 'multiple rules, with abbreviated names' do
            context 'one of them has offenses' do
              let(:source) do
                '# rubocop:disable MethodLength, ClassLength, Debugger'
              end
              let(:rule_disabled_line_ranges) do
                { 'Metrics/ClassLength' => [1..Float::INFINITY],
                  'Metrics/MethodLength' => [1..Float::INFINITY],
                  'Lint/Debugger' => [1..Float::INFINITY] }
              end
              let(:offenses) do
                [
                  RuboCop::Rule::Offense.new(:convention,
                                            OpenStruct.new(line: 7, column: 0),
                                            'Method has too many lines.',
                                            'Metrics/MethodLength')
                ]
              end

              it 'returns an offense and warns about missing departments' do
                expect(rule.messages)
                  .to eq(['Unnecessary disabling of `Metrics/ClassLength`.',
                          'Unnecessary disabling of `Lint/Debugger`.'])
                expect(rule.highlights).to eq(%w[ClassLength Debugger])
                expect($stderr.string).to eq(<<~OUTPUT)
                  test: Warning: no department given for MethodLength.
                  test: Warning: no department given for ClassLength.
                  test: Warning: no department given for Debugger.
                OUTPUT
              end
            end
          end

          context 'comment is not at the beginning of the file' do
            context 'and not all rules have offenses' do
              let(:source) do
                <<~RUBY
                  puts 1
                  # rubocop:disable Metrics/MethodLength, Metrics/ClassLength
                RUBY
              end
              let(:rule_disabled_line_ranges) do
                { 'Metrics/ClassLength' => [2..Float::INFINITY],
                  'Metrics/MethodLength' => [2..Float::INFINITY] }
              end
              let(:offenses) do
                [
                  RuboCop::Rule::Offense.new(:convention,
                                            OpenStruct.new(line: 7, column: 0),
                                            'Method has too many lines.',
                                            'Metrics/MethodLength')
                ]
              end

              it 'registers an offense' do
                expect(rule.messages).to eq(
                  ['Unnecessary disabling of `Metrics/ClassLength`.']
                )
                expect(rule.highlights).to eq(['Metrics/ClassLength'])
              end
            end
          end

          context 'misspelled rules' do
            let(:source) do
              '# rubocop:disable Metrics/MethodLenght, KlassLength'
            end
            let(:rule_disabled_line_ranges) do
              { 'KlassLength' => [1..Float::INFINITY],
                'Metrics/MethodLenght' => [1..Float::INFINITY] }
            end

            it 'returns an offense' do
              expect(rule.messages)
                .to eq(['Unnecessary disabling of `KlassLength` (unknown ' \
                        'rule), `Metrics/MethodLenght` (did you mean ' \
                        '`Metrics/MethodLength`?).'])
            end
          end

          context 'all rules' do
            let(:source) { '# rubocop : disable all' }
            let(:rule_disabled_line_ranges) do
              {
                'Metrics/MethodLength' => [1..Float::INFINITY],
                'Metrics/ClassLength' => [1..Float::INFINITY]
                # etc... (no need to include all rules here)
              }
            end

            it 'returns an offense' do
              expect(rule.messages).to eq(['Unnecessary disabling of all rules.'])
              expect(rule.highlights).to eq([source])
            end
          end

          context 'itself and all rules' do
            context 'disabled on different ranges' do
              let(:source) do
                ['# rubocop:disable Lint/RedundantRuleDisableDirective',
                 '# rubocop:disable all'].join("\n")
              end

              let(:rule_disabled_line_ranges) do
                { 'Lint/RedundantRuleDisableDirective' => [1..Float::INFINITY],
                  'all' => [2..Float::INFINITY] }
              end

              it 'does not return an offense' do
                expect(rule.offenses.empty?).to be(true)
              end
            end
          end
        end
      end

      context 'and there are two offenses' do
        let(:message) do
          'Replace class var @@class_var with a class instance var.'
        end
        let(:rule_name) { 'Style/ClassVars' }
        let(:offenses) do
          offense_lines.map do |line|
            RuboCop::Rule::Offense.new(:convention,
                                      OpenStruct.new(line: line, column: 3),
                                      message,
                                      rule_name)
          end
        end

        context 'and a comment disables' do
          context 'one rule twice' do
            let(:source) do
              <<~RUBY
                class One
                  # rubocop:disable Style/ClassVars
                  @@class_var = 1
                end

                class Two
                  # rubocop:disable Style/ClassVars
                  @@class_var = 2
                end
              RUBY
            end
            let(:offense_lines) { [3, 8] }
            let(:rule_disabled_line_ranges) do
              { 'Style/ClassVars' => [2..7, 7..9] }
            end

            it 'returns an offense' do
              expect(rule.messages)
                .to eq(['Unnecessary disabling of `Style/ClassVars`.'])
              expect(rule.highlights)
                .to eq(['# rubocop:disable Style/ClassVars'])
            end
          end

          context 'one rule and then all rules' do
            let(:source) do
              <<~RUBY
                class One
                  # rubocop:disable Style/ClassVars
                  # rubocop:disable all
                  @@class_var = 1
                end
              RUBY
            end
            let(:offense_lines) { [4] }
            let(:rule_disabled_line_ranges) do
              { 'Style/ClassVars' => [2..3, 3..Float::INFINITY] }
            end

            it 'returns an offense' do
              expect(rule.messages)
                .to eq(['Unnecessary disabling of `Style/ClassVars`.'])
              expect(rule.highlights)
                .to eq(['# rubocop:disable Style/ClassVars'])
            end
          end
        end
      end

      context 'and there is an offense' do
        let(:offenses) do
          [
            RuboCop::Rule::Offense.new(:convention,
                                      OpenStruct.new(line: 7, column: 0),
                                      'Tab detected.',
                                      'Layout/IndentationStyle')
          ]
        end

        context 'and a comment disables' do
          context 'that rule' do
            let(:source) { '# rubocop:disable Layout/IndentationStyle' }
            let(:rule_disabled_line_ranges) do
              { 'Layout/IndentationStyle' => [1..100] }
            end

            it 'returns an empty array' do
              expect(rule.offenses.empty?).to be(true)
            end
          end

          context 'that rule but on other lines' do
            let(:source) do
              ("\n" * 9) << '# rubocop:disable Layout/IndentationStyle'
            end
            let(:rule_disabled_line_ranges) do
              { 'Layout/IndentationStyle' => [10..12] }
            end

            it 'returns an offense' do
              expect(rule.messages)
                .to eq(['Unnecessary disabling of `Layout/IndentationStyle`.'])
              expect(rule.highlights).to eq(
                ['# rubocop:disable Layout/IndentationStyle']
              )
            end
          end

          context 'all rules' do
            let(:source) { '# rubocop : disable all' }
            let(:rule_disabled_line_ranges) do
              {
                'Metrics/MethodLength' => [1..Float::INFINITY],
                'Metrics/ClassLength' => [1..Float::INFINITY]
                # etc... (no need to include all rules here)
              }
            end

            it 'returns an empty array' do
              expect(rule.offenses.empty?).to be(true)
            end
          end
        end
      end
    end
  end
end
