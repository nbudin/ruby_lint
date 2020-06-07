# frozen_string_literal: true

module RuboCop
  module Rule
    module Style
      #
      # This cop checks for BEGIN blocks.
      #
      # @example
      #   # bad
      #   BEGIN { test }
      #
      class BeginBlock < Rule
        MSG = 'Avoid the use of `BEGIN` blocks.'

        def on_preexe(node)
          add_offense(node, location: :keyword)
        end
      end
    end
  end
end
