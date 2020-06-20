# frozen_string_literal: true

module RuboCop
  module Rule
    module Metrics
      # This cop checks if the length of a method exceeds some maximum value.
      # Comment lines can optionally be ignored.
      # The maximum allowed length is configurable.
      class MethodLength < Rule
        include TooManyLines

        LABEL = 'Method'

        def on_def(node)
          excluded_methods = rule_config['ExcludedMethods']
          return if excluded_methods.include?(String(node.method_name))

          check_code_length(node)
        end
        alias on_defs on_def

        def on_block(node)
          return unless node.send_node.method?(:define_method)

          check_code_length(node)
        end

        private

        def cop_label
          LABEL
        end
      end
    end
  end
end