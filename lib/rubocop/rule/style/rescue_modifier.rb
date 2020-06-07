# frozen_string_literal: true

module RuboCop
  module Rule
    module Style
      # This cop checks for uses of rescue in its modifier form.
      #
      # The cop to check `rescue` in its modifier form is added for following
      # reasons:
      #
      # * The syntax of modifier form `rescue` can be misleading because it
      #   might led us to believe that `rescue` handles the given exception
      #   but it actually rescue all exceptions to return the given rescue
      #   block. In this case, value returned by handle_error or
      #   SomeException.
      #
      # * Modifier form `rescue` would rescue all the exceptions. It would
      #   silently skip all exception or errors and handle the error.
      #   Example: If `NoMethodError` is raised, modifier form rescue would
      #   handle the exception.
      #
      # @example
      #   # bad
      #   some_method rescue handle_error
      #
      #   # bad
      #   some_method rescue SomeException
      #
      #   # good
      #   begin
      #     some_method
      #   rescue
      #     handle_error
      #   end
      #
      #   # good
      #   begin
      #     some_method
      #   rescue SomeException
      #     handle_error
      #   end
      class RescueModifier < Rule
        include Alignment
        include RescueNode

        MSG = 'Avoid using `rescue` in its modifier form.'

        def on_resbody(node)
          return unless rescue_modifier?(node)

          add_offense(node.parent)
        end

        def autocorrect(node)
          operation, rescue_modifier, = *node
          *_, rescue_args = *rescue_modifier

          indent = indentation(node)
          correction =
            "begin\n" \
            "#{operation.source.gsub(/^/, indent)}" \
            "\n#{offset(node)}rescue\n" \
            "#{rescue_args.source.gsub(/^/, indent)}" \
            "\n#{offset(node)}end"

          lambda do |corrector|
            corrector.replace(node, correction)
          end
        end
      end
    end
  end
end
