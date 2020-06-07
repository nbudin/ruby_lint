# frozen_string_literal: true

module RuboCop
  module Rule
    module Style
      # This cop checks symbol literal syntax.
      #
      # @example
      #
      #   # bad
      #   :"symbol"
      #
      #   # good
      #   :symbol
      class SymbolLiteral < Rule
        MSG = 'Do not use strings for word-like symbol literals.'

        def on_sym(node)
          return unless /\A:["'][A-Za-z_]\w*["']\z/.match?(node.source)

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node, node.source.delete(%q('")))
          end
        end
      end
    end
  end
end
