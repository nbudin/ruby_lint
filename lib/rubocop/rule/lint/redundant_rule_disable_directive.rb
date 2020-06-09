# frozen_string_literal: true

# The Lint/RedundantRuleDisableDirective rule needs to be disabled so as
# to be able to provide a (bad) example of a redundant disable.
# rubocop:disable Lint/RedundantRuleDisableDirective
module RuboCop
  module Rule
    module Lint
      # This rule detects instances of rubocop:disable comments that can be
      # removed without causing any offenses to be reported. It's implemented
      # as a rule in that it inherits from the Cop base class and calls
      # add_offense. The unusual part of its implementation is that it doesn't
      # have any on_* methods or an investigate method. This means that it
      # doesn't take part in the investigation phase when the other rules do
      # their work. Instead, it waits until it's called in a later stage of the
      # execution. The reason it can't be implemented as a normal rule is that
      # it depends on the results of all other rules to do its work.
      #
      #
      # @example
      #   # bad
      #   # rubocop:disable Layout/LineLength
      #   x += 1
      #   # rubocop:enable Layout/LineLength
      #
      #   # good
      #   x += 1
      class RedundantRuleDisableDirective < Rule
        include RangeHelp

        COP_NAME = 'Lint/RedundantRuleDisableDirective'

        def check(offenses, rule_disabled_line_ranges, comments)
          redundant_rules = Hash.new { |h, k| h[k] = Set.new }

          each_redundant_disable(rule_disabled_line_ranges,
                                 offenses, comments) do |comment, redundant_rule|
            redundant_rules[comment].add(redundant_rule)
          end

          add_offenses(redundant_rules)
        end

        def autocorrect(args)
          lambda do |corrector|
            ranges, range = *args # Ranges are sorted by position.

            range = if range.source.start_with?('#')
                      comment_range_with_surrounding_space(range)
                    else
                      directive_range_in_list(range, ranges)
                    end

            corrector.remove(range)
          end
        end

        private

        def comment_range_with_surrounding_space(range)
          # Eat the entire comment, the preceding space, and the preceding
          # newline if there is one.
          original_begin = range.begin_pos
          range = range_with_surrounding_space(range: range,
                                               side: :left,
                                               newlines: true)
          range_with_surrounding_space(range: range,
                                       side: :right,
                                       # Special for a comment that
                                       # begins the file: remove
                                       # the newline at the end.
                                       newlines: original_begin.zero?)
        end

        def directive_range_in_list(range, ranges)
          # Is there any rule between this one and the end of the line, which
          # is NOT being removed?
          if ends_its_line?(ranges.last) && trailing_range?(ranges, range)
            # Eat the comma on the left.
            range = range_with_surrounding_space(range: range, side: :left)
            range = range_with_surrounding_comma(range, :left)
          end

          range = range_with_surrounding_comma(range, :right)
          # Eat following spaces up to EOL, but not the newline itself.
          range_with_surrounding_space(range: range,
                                       side: :right,
                                       newlines: false)
        end

        def each_redundant_disable(rule_disabled_line_ranges, offenses, comments,
                                   &block)
          disabled_ranges = rule_disabled_line_ranges[COP_NAME] || [0..0]

          rule_disabled_line_ranges.each do |rule, line_ranges|
            each_already_disabled(line_ranges,
                                  disabled_ranges, comments) do |comment|
              yield comment, rule
            end

            each_line_range(line_ranges, disabled_ranges, offenses, comments,
                            rule, &block)
          end
        end

        def each_line_range(line_ranges, disabled_ranges, offenses, comments,
                            rule)
          line_ranges.each_with_index do |line_range, ix|
            comment = comments.find { |c| c.loc.line == line_range.begin }
            next if ignore_offense?(disabled_ranges, line_range)

            redundant_rule = find_redundant(comment, offenses, rule, line_range,
                                           line_ranges[ix + 1])
            yield comment, redundant_rule if redundant_rule
          end
        end

        def each_already_disabled(line_ranges, disabled_ranges, comments)
          line_ranges.each_cons(2) do |previous_range, range|
            next if ignore_offense?(disabled_ranges, range)
            next if previous_range.end != range.begin

            # If a rule is disabled in a range that begins on the same line as
            # the end of the previous range, it means that the rule was
            # already disabled by an earlier comment. So it's redundant
            # whether there are offenses or not.
            redundant_comment = comments.find do |c|
              c.loc.line == range.begin &&
                # Comments disabling all rules don't count since it's reasonable
                # to disable a few select rules first and then all rules further
                # down in the code.
                !all_disabled?(c)
            end
            yield redundant_comment if redundant_comment
          end
        end

        def find_redundant(comment, offenses, rule, line_range, next_line_range)
          if all_disabled?(comment)
            # If there's a disable all comment followed by a comment
            # specifically disabling `rule`, we don't report the `all`
            # comment. If the disable all comment is truly redundant, we will
            # detect that when examining the comments of another rule, and we
            # get the full line range for the disable all.
            if (next_line_range.nil? ||
                line_range.last != next_line_range.first) &&
               offenses.none? { |o| line_range.cover?(o.line) }
              'all'
            end
          else
            rule_offenses = offenses.select { |o| o.rule_name == rule }
            rule if rule_offenses.none? { |o| line_range.cover?(o.line) }
          end
        end

        def all_disabled?(comment)
          comment.text =~ /rubocop\s*:\s*(?:disable|todo)\s+all\b/
        end

        def ignore_offense?(disabled_ranges, line_range)
          disabled_ranges.any? do |range|
            range.cover?(line_range.min) && range.cover?(line_range.max)
          end
        end

        def directive_count(comment)
          match = comment.text.match(CommentConfig::COMMENT_DIRECTIVE_REGEXP)
          _, rules_string = match.captures
          rules_string.split(/,\s*/).size
        end

        def add_offenses(redundant_rules)
          redundant_rules.each do |comment, rules|
            if all_disabled?(comment) ||
               directive_count(comment) == rules.size
              add_offense_for_entire_comment(comment, rules)
            else
              add_offense_for_some_rules(comment, rules)
            end
          end
        end

        def add_offense_for_entire_comment(comment, rules)
          location = comment.loc.expression
          rule_list = rules.sort.map { |c| describe(c) }

          add_offense(
            [[location], location],
            location: location,
            message: "Unnecessary disabling of #{rule_list.join(', ')}."
          )
        end

        def add_offense_for_some_rules(comment, rules)
          rule_ranges = rules.map { |c| [c, rule_range(comment, c)] }
          rule_ranges.sort_by! { |_, r| r.begin_pos }
          ranges = rule_ranges.map { |_, r| r }

          rule_ranges.each do |rule, range|
            add_offense(
              [ranges, range],
              location: range,
              message: "Unnecessary disabling of #{describe(rule)}."
            )
          end
        end

        def rule_range(comment, rule)
          matching_range(comment.loc.expression, rule) ||
            matching_range(comment.loc.expression, Badge.parse(rule).rule_name) ||
            raise("Couldn't find #{rule} in comment: #{comment.text}")
        end

        def matching_range(haystack, needle)
          offset = haystack.source.index(needle)
          return unless offset

          offset += haystack.begin_pos
          Parser::Source::Range.new(haystack.source_buffer, offset,
                                    offset + needle.size)
        end

        def trailing_range?(ranges, range)
          ranges
            .drop_while { |r| !r.equal?(range) }
            .each_cons(2)
            .map { |range1, range2| range1.end.join(range2.begin).source }
            .all? { |intervening| intervening =~ /\A\s*,\s*\Z/ }
        end

        def describe(rule)
          if rule == 'all'
            'all rules'
          elsif all_rule_names.include?(rule)
            "`#{rule}`"
          else
            similar = NameSimilarity.find_similar_name(rule, all_rule_names)
            if similar
              "`#{rule}` (did you mean `#{similar}`?)"
            else
              "`#{rule}` (unknown rule)"
            end
          end
        end

        def all_rule_names
          @all_rule_names ||= Rule.registry.names
        end

        def ends_its_line?(range)
          line = range.source_buffer.source_line(range.last_line)
          (line =~ /\s*\z/) == range.last_column
        end
      end
    end
  end
end
# rubocop:enable Lint/RedundantRuleDisableDirective
