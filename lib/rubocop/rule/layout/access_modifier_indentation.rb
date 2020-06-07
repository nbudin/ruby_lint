# frozen_string_literal: true

module RuboCop
  module Rule
    module Layout
      # Bare access modifiers (those not applying to specific methods) should be
      # indented as deep as method definitions, or as deep as the class/module
      # keyword, depending on configuration.
      #
      # @example EnforcedStyle: indent (default)
      #   # bad
      #   class Plumbus
      #   private
      #     def smooth; end
      #   end
      #
      #   # good
      #   class Plumbus
      #     private
      #     def smooth; end
      #   end
      #
      # @example EnforcedStyle: outdent
      #   # bad
      #   class Plumbus
      #     private
      #     def smooth; end
      #   end
      #
      #   # good
      #   class Plumbus
      #   private
      #     def smooth; end
      #   end
      class AccessModifierIndentation < Rule
        include Alignment
        include ConfigurableEnforcedStyle
        include RangeHelp

        MSG = '%<style>s access modifiers like `%<node>s`.'

        def on_class(node)
          return unless node.body&.begin_type?

          check_body(node.body, node)
        end
        alias on_sclass on_class
        alias on_module on_class
        alias on_block  on_class

        def autocorrect(node)
          AlignmentCorrector.correct(processed_source, node, @column_delta)
        end

        private

        def check_body(body, node)
          modifiers = body.each_child_node(:send)
                          .select(&:bare_access_modifier?)
          end_range = node.loc.end

          modifiers.each { |modifier| check_modifier(modifier, end_range) }
        end

        def check_modifier(send_node, end_range)
          offset = column_offset_between(send_node.source_range, end_range)

          @column_delta = expected_indent_offset - offset
          if @column_delta.zero?
            correct_style_detected
          else
            add_offense(send_node) do
              if offset == unexpected_indent_offset
                opposite_style_detected
              else
                unrecognized_style_detected
              end
            end
          end
        end

        def message(node)
          format(MSG, style: style.capitalize, node: node.loc.selector.source)
        end

        def expected_indent_offset
          style == :outdent ? 0 : configured_indentation_width
        end

        # An offset that is not expected, but correct if the configuration is
        # changed.
        def unexpected_indent_offset
          configured_indentation_width - expected_indent_offset
        end
      end
    end
  end
end
