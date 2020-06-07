# frozen_string_literal: true

module RuboCop
  module Rule
    module Test
      class ClassMustBeAModuleCop < Rubocop::Rule::Rule
        def on_class(node)
          add_offense(node, message: 'Class must be a Module')
        end

        def autocorrect(node)
          ->(corrector) { corrector.replace(node.loc.keyword, 'module') }
        end
      end
    end
  end
end
