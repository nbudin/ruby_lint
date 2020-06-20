# frozen_string_literal: true

# rubocop:disable Lint/RedundantCopDisableDirective
module RuboCop
  module Rule
    module Lint
      # This rule checks that there is an `# rubocop:enable ...` statement
      # after a `# rubocop:disable ...` statement. This will prevent leaving
      # rule disables on wide ranges of code, that latter contributors to
      # a file wouldn't be aware of.
      #
      # @example
      #   # Lint/MissingRuleEnableDirective:
      #   #   MaximumRangeSize: .inf
      #
      #   # good
      #   # rubocop:disable Layout/SpaceAroundOperators
      #   x= 0
      #   # rubocop:enable Layout/SpaceAroundOperators
      #   # y = 1
      #   # EOF
      #
      #   # bad
      #   # rubocop:disable Layout/SpaceAroundOperators
      #   x= 0
      #   # EOF
      #
      # @example
      #   # Lint/MissingRuleEnableDirective:
      #   #   MaximumRangeSize: 2
      #
      #   # good
      #   # rubocop:disable Layout/SpaceAroundOperators
      #   x= 0
      #   # With the previous, there are 2 lines on which rule is disabled.
      #   # rubocop:enable Layout/SpaceAroundOperators
      #
      #   # bad
      #   # rubocop:disable Layout/SpaceAroundOperators
      #   x= 0
      #   x += 1
      #   # Including this, that's 3 lines on which the rule is disabled.
      #   # rubocop:enable Layout/SpaceAroundOperators
      #
      class MissingRuleEnableDirective < Rule
        include RangeHelp

        MSG = 'Re-enable %<rule>s rule with `# rubocop:enable` after ' \
              'disabling it.'
        MSG_BOUND = 'Re-enable %<rule>s rule within %<max_range>s lines after ' \
                    'disabling it.'

        def investigate(processed_source)
          max_range = rule_config['MaximumRangeSize']
          processed_source.disabled_line_ranges.each do |rule, line_ranges|
            line_ranges.each do |line_range|
              # This has to remain a strict inequality to handle
              # the case when max_range is Float::INFINITY
              next if line_range.max - line_range.min < max_range + 2

              range = source_range(processed_source.buffer,
                                   line_range.min,
                                   (0..0))
              add_offense(range,
                          location: range,
                          message: message(max_range: max_range, rule: rule))
            end
          end
        end

        private

        def message(max_range:, rule:)
          if max_range == Float::INFINITY
            format(MSG, rule: rule)
          else
            format(MSG_BOUND, rule: rule, max_range: max_range)
          end
        end
      end
    end
  end
end
# rubocop:enable Lint/RedundantRuleDisableDirective, Layout/SpaceAroundOperators
