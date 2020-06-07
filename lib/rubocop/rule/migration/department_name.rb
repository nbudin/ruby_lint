# frozen_string_literal: true

module RuboCop
  module Rule
    module Migration
      # Check that cop names in rubocop:disable comments are given with
      # department name.
      class DepartmentName < Rule
        include RangeHelp

        MSG = 'Department name is missing.'

        DISABLE_COMMENT_FORMAT =
          /\A(# *rubocop *: *((dis|en)able|todo) +)(.*)/.freeze

        # The token that makes up a disable comment.
        # The allowed specification for comments after `# rubocop: disable` is
        # `DepartmentName/RuleName` or` all`.
        DISABLING_RULES_CONTENT_TOKEN = %r{[A-z]+/[A-z]+|all}.freeze

        def investigate(processed_source)
          processed_source.each_comment do |comment|
            next if comment.text !~ DISABLE_COMMENT_FORMAT

            offset = Regexp.last_match(1).length

            Regexp.last_match(4).scan(/[^,]+|\W+/) do |name|
              trimmed_name = name.strip

              unless valid_content_token?(trimmed_name)
                check_cop_name(trimmed_name, comment, offset)
              end

              break if contain_unexpected_character_for_department_name?(name)

              offset += name.length
            end
          end
        end

        def autocorrect(range)
          shall_warn = false
          cop_name = range.source
          qualified_rule_name = Rule.registry.qualified_rule_name(rule_name,
                                                               nil, shall_warn)
          unless qualified_rule_name.include?('/')
            qualified_rule_name = qualified_legacy_rule_name(rule_name)
          end

          ->(corrector) { corrector.replace(range, qualified_rule_name) }
        end

        private

        def disable_comment_offset
          Regexp.last_match(1).length
        end

        def check_cop_name(name, comment, offset)
          start = comment.location.expression.begin_pos + offset
          range = range_between(start, start + name.length)

          add_offense(range, location: range)
        end

        def valid_content_token?(content_token)
          /\W+/.match?(content_token) ||
            DISABLING_RULES_CONTENT_TOKEN.match?(content_token)
        end

        def contain_unexpected_character_for_department_name?(name)
          name.match?(%r{[^A-z/, ]})
        end

        def qualified_legacy_rule_name(rule_name)
          legacy_rule_names = RuboCop::ConfigObsoletion::OBSOLETE_RULES.keys

          legacy_rule_names.detect do |legacy_rule_name|
            legacy_rule_name.split('/')[1] == rule_name
          end
        end
      end
    end
  end
end
