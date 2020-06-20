# frozen_string_literal: true

module RuboCop
  module Rule
    module Lint
      # This is not actually a rule. It does not inspect anything. It just
      # provides methods to repack Parser's diagnostics/errors
      # into RuboCop's offenses.
      class Syntax < Rule
        PseudoSourceRange = Struct.new(:line, :column, :source_line, :begin_pos,
                                       :end_pos)

        ERROR_SOURCE_RANGE = PseudoSourceRange.new(1, 0, '', 0, 1).freeze

        def self.offenses_from_processed_source(processed_source,
                                                config, options)
          rule = new(config, options)

          rule.add_offense_from_error(processed_source.parser_error) if processed_source.parser_error

          processed_source.diagnostics.each do |diagnostic|
            rule.add_offense_from_diagnostic(diagnostic,
                                            processed_source.ruby_version)
          end

          rule.offenses
        end

        def add_offense_from_diagnostic(diagnostic, ruby_version)
          message =
            "#{diagnostic.message}\n(Using Ruby #{ruby_version} parser; " \
            'configure using `TargetRubyVersion` parameter, under `AllRules`)'
          add_offense(nil,
                      location: diagnostic.location,
                      message: message,
                      severity: diagnostic.level)
        end

        def add_offense_from_error(error)
          message = beautify_message(error.message)
          add_offense(nil,
                      location: ERROR_SOURCE_RANGE,
                      message: message,
                      severity: :fatal)
        end

        private

        def beautify_message(message)
          message = message.capitalize
          message << '.' unless message.end_with?('.')
          message
        end
      end
    end
  end
end