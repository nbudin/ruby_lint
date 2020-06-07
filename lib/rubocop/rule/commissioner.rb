# frozen_string_literal: true

module RuboCop
  module Rule
    # Commissioner class is responsible for processing the AST and delegating
    # work to the specified rules.
    class Commissioner
      include RuboCop::AST::Traversal

      attr_reader :errors

      def initialize(rules, forces = [], options = {})
        @rules = rules
        @forces = forces
        @options = options
        @callbacks = {}

        reset_errors
      end

      # Create methods like :on_send, :on_super, etc. They will be called
      # during AST traversal and try to call corresponding methods on rules.
      # A call to `super` is used
      # to continue iterating over the children of a node.
      # However, if we know that a certain node type (like `int`) never has
      # child nodes, there is no reason to pay the cost of calling `super`.
      Parser::Meta::NODE_TYPES.each do |node_type|
        method_name = :"on_#{node_type}"
        next unless method_defined?(method_name)

        define_method(method_name) do |node|
          trigger_responding_rules(method_name, node)
          super(node) unless NO_CHILD_NODES.include?(node_type)
        end
      end

      def investigate(processed_source)
        reset_errors
        reset_callbacks
        prepare(processed_source)
        invoke_custom_processing(@rules, processed_source)
        invoke_custom_processing(@forces, processed_source)
        walk(processed_source.ast) unless processed_source.blank?
        invoke_custom_post_walk_processing(@rules, processed_source)
        @rules.flat_map(&:offenses)
      end

      private

      def trigger_responding_rules(callback, node)
        @callbacks[callback] ||= @rules.select do |rule|
          rule.respond_to?(callback)
        end
        @callbacks[callback].each do |rule|
          with_rule_error_handling(rule, node) do
            rule.send(callback, node)
          end
        end
      end

      def reset_errors
        @errors = []
      end

      def reset_callbacks
        @callbacks.clear
      end

      # TODO: Bad design.
      def prepare(processed_source)
        @rules.each { |rule| rule.processed_source = processed_source }
      end

      # There are rules/forces that require their own custom processing.
      # If they define the #investigate method, all input parameters passed
      # to the commissioner will be passed to the rule too in order to do
      # its own processing.
      #
      # These custom processors are invoked before the AST traversal,
      # so they can build initial state that is later used by callbacks
      # during the AST traversal.
      def invoke_custom_processing(rules_or_forces, processed_source)
        rules_or_forces.each do |rule|
          next unless rule.respond_to?(:investigate)

          with_rule_error_handling(rule) do
            rule.investigate(processed_source)
          end
        end
      end

      # There are rules that require their own custom processing **after**
      # the AST traversal. By performing the walk before invoking these
      # custom processors, we allow these rules to build their own
      # state during the primary AST traversal instead of performing their
      # own AST traversals. Minimizing the number of walks is more efficient.
      #
      # If they define the #investigate_post_walk method, all input parameters
      # passed to the commissioner will be passed to the rule too in order to do
      # its own processing.
      def invoke_custom_post_walk_processing(rules, processed_source)
        rules.each do |rule|
          next unless rule.respond_to?(:investigate_post_walk)

          with_rule_error_handling(rule) do
            rule.investigate_post_walk(processed_source)
          end
        end
      end

      # Allow blind rescues here, since we're absorbing and packaging or
      # re-raising exceptions that can be raised from within the individual
      # rules' `#investigate` methods.
      def with_rule_error_handling(rule, node = nil)
        yield
      rescue StandardError => e
        raise e if @options[:raise_error]

        err = ErrorWithAnalyzedFileLocation.new(cause: e, node: node, rule: rule)
        @errors << err
      end
    end
  end
end
