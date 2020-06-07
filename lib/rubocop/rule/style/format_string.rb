# frozen_string_literal: true

module RuboCop
  module Rule
    module Style
      # This cop enforces the use of a single string formatting utility.
      # Valid options include Kernel#format, Kernel#sprintf and String#%.
      #
      # The detection of String#% cannot be implemented in a reliable
      # manner for all cases, so only two scenarios are considered -
      # if the first argument is a string literal and if the second
      # argument is an array literal.
      #
      # @example EnforcedStyle: format (default)
      #   # bad
      #   puts sprintf('%10s', 'hoge')
      #   puts '%10s' % 'hoge'
      #
      #   # good
      #   puts format('%10s', 'hoge')
      #
      # @example EnforcedStyle: sprintf
      #   # bad
      #   puts format('%10s', 'hoge')
      #   puts '%10s' % 'hoge'
      #
      #   # good
      #   puts sprintf('%10s', 'hoge')
      #
      # @example EnforcedStyle: percent
      #   # bad
      #   puts format('%10s', 'hoge')
      #   puts sprintf('%10s', 'hoge')
      #
      #   # good
      #   puts '%10s' % 'hoge'
      #
      class FormatString < Rule
        include ConfigurableEnforcedStyle

        MSG = 'Favor `%<prefer>s` over `%<current>s`.'

        def_node_matcher :formatter, <<~PATTERN
          {
            (send nil? ${:sprintf :format} _ _ ...)
            (send {str dstr} $:% ... )
            (send !nil? $:% {array hash})
          }
        PATTERN

        def_node_matcher :variable_argument?, <<~PATTERN
          (send {str dstr} :% {send_type? lvar_type?})
        PATTERN

        def on_send(node)
          formatter(node) do |selector|
            detected_style = selector == :% ? :percent : selector

            return if detected_style == style

            add_offense(node, location: :selector,
                              message: message(detected_style))
          end
        end

        def message(detected_style)
          format(MSG,
                 prefer: method_name(style),
                 current: method_name(detected_style))
        end

        def method_name(style_name)
          style_name == :percent ? 'String#%' : style_name
        end

        def autocorrect(node)
          return if variable_argument?(node)

          lambda do |corrector|
            case node.method_name
            when :%
              autocorrect_from_percent(corrector, node)
            when :format, :sprintf
              case style
              when :percent
                autocorrect_to_percent(corrector, node)
              when :format, :sprintf
                corrector.replace(node.loc.selector, style.to_s)
              end
            end
          end
        end

        private

        def autocorrect_from_percent(corrector, node)
          percent_rhs = node.first_argument
          args = case percent_rhs.type
                 when :array, :hash
                   percent_rhs.children.map(&:source).join(', ')
                 else
                   percent_rhs.source
                 end

          corrected = "#{style}(#{node.receiver.source}, #{args})"

          corrector.replace(node, corrected)
        end

        def autocorrect_to_percent(corrector, node)
          format_arg, *param_args = node.arguments
          format = format_arg.source

          args = if param_args.one?
                   arg = param_args.last

                   arg.hash_type? ? "{ #{arg.source} }" : arg.source
                 else
                   "[#{param_args.map(&:source).join(', ')}]"
                 end

          corrector.replace(node, "#{format} % #{args}")
        end
      end
    end
  end
end
