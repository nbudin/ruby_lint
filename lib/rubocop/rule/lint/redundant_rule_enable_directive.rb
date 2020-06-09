# frozen_string_literal: true

# The Lint/RedundantRuleEnableDirective and Lint/RedundantRuleDisableDirective
# rules need to be disabled so as to be able to provide a (bad) example of an
# unneeded enable.

# rubocop:disable Lint/RedundantRuleEnableDirective
# rubocop:disable Lint/RedundantRuleDisableDirective
module RuboCop
  module Rule
    module Lint
      # This rule detects instances of rubocop:enable comments that can be
      # removed.
      #
      # When comment enables all rules at once `rubocop:enable all`
      # that rule checks whether any rule was actually enabled.
      # @example
      #   # bad
      #   foo = 1
      #   # rubocop:enable Layout/LineLength
      #
      #   # good
      #   foo = 1
      # @example
      #   # bad
      #   # rubocop:disable Style/StringLiterals
      #   foo = "1"
      #   # rubocop:enable Style/StringLiterals
      #   baz
      #   # rubocop:enable all
      #
      #   # good
      #   # rubocop:disable Style/StringLiterals
      #   foo = "1"
      #   # rubocop:enable all
      #   baz
      class RedundantRuleEnableDirective < Rule
        include RangeHelp
        include SurroundingSpace

        MSG = 'Unnecessary enabling of %<rule>s.'

        def investigate(processed_source)
          return if processed_source.blank?

          offenses = processed_source.comment_config.extra_enabled_comments
          offenses.each do |comment, name|
            add_offense(
              [comment, name],
              location: range_of_offense(comment, name),
              message: format(MSG, rule: all_or_name(name))
            )
          end
        end

        def autocorrect(comment_and_name)
          lambda do |corrector|
            corrector.remove(range_with_comma(*comment_and_name))
          end
        end

        private

        def range_of_offense(comment, name)
          start_pos = comment_start(comment) + rule_name_indention(comment, name)
          range_between(start_pos, start_pos + name.size)
        end

        def comment_start(comment)
          comment.loc.expression.begin_pos
        end

        def rule_name_indention(comment, name)
          comment.text.index(name)
        end

        def range_with_comma(comment, name)
          source = comment.loc.expression.source

          begin_pos = rule_name_indention(comment, name)
          end_pos = begin_pos + name.size
          begin_pos = reposition(source, begin_pos, -1)
          end_pos = reposition(source, end_pos, 1)

          comma_pos =
            if source[begin_pos - 1] == ','
              :before
            elsif source[end_pos] == ','
              :after
            else
              :none
            end

          range_to_remove(begin_pos, end_pos, comma_pos, comment)
        end

        def range_to_remove(begin_pos, end_pos, comma_pos, comment)
          start = comment_start(comment)

          case comma_pos
          when :before
            range_between(start + begin_pos - 1, start + end_pos)
          when :after
            range_between(start + begin_pos, start + end_pos + 1)
          else
            range_between(start, comment.loc.expression.end_pos)
          end
        end

        def all_or_name(name)
          name == 'all' ? 'all rules' : name
        end
      end
    end
  end
end

# rubocop:enable Lint/RedundantRuleDisableDirective
# rubocop:enable Lint/RedundantRuleEnableDirective
