# frozen_string_literal: true

module RuboCop
  module Rule
    module Style
      # This cop checks for variable interpolation (like "#@ivar").
      #
      # @example
      #   # bad
      #   "His name is #$name"
      #   /check #$pattern/
      #   "Let's go to the #@store"
      #
      #   # good
      #   "His name is #{$name}"
      #   /check #{$pattern}/
      #   "Let's go to the #{@store}"
      class VariableInterpolation < Rule
        include Interpolation

        MSG = 'Replace interpolated variable `%<variable>s` ' \
              'with expression `#{%<variable>s}`.'

        def on_node_with_interpolations(node)
          var_nodes(node.children).each do |var_node|
            add_offense(var_node)
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node, "{#{node.source}}")
          end
        end

        private

        def message(node)
          format(MSG, variable: node.source)
        end

        def var_nodes(nodes)
          nodes.select { |n| n.variable? || n.reference? }
        end
      end
    end
  end
end
