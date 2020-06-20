# frozen_string_literal: true

module RuboCop
  module Rule
    module Layout
      # This cop checks if empty lines around the bodies of modules match
      # the configuration.
      #
      # @example EnforcedStyle: empty_lines
      #   # good
      #
      #   module Foo
      #
      #     def bar
      #       # ...
      #     end
      #
      #   end
      #
      # @example EnforcedStyle: empty_lines_except_namespace
      #   # good
      #
      #   module Foo
      #     module Bar
      #
      #       # ...
      #
      #     end
      #   end
      #
      # @example EnforcedStyle: empty_lines_special
      #   # good
      #   module Foo
      #
      #     def bar; end
      #
      #   end
      #
      # @example EnforcedStyle: no_empty_lines (default)
      #   # good
      #
      #   module Foo
      #     def bar
      #       # ...
      #     end
      #   end
      class EmptyLinesAroundModuleBody < Rule
        include EmptyLinesAroundBody

        KIND = 'module'

        def on_module(node)
          check(node, node.body)
        end

        def autocorrect(node)
          EmptyLineCorrector.correct(node)
        end
      end
    end
  end
end