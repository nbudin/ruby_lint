# frozen_string_literal: true

module RuboCop
  module Rule
    # Identifier of all rules containing a department and rule name.
    #
    # All rules are identified by their badge. For example, the badge for
    # `RuboCop::Rule::Layout::IndentationStyle` is `Layout/IndentationStyle`.
    # Badges can be parsed as either `Department/RuleName` or just `RuleName` to
    # allow for badge references in source files that omit the department for
    # RuboCop to infer.
    class Badge
      # Error raised when a badge parse fails.
      class InvalidBadge < Error
        MSG = 'Invalid badge %<badge>p. ' \
              'Expected `Department/RuleName` or `RuleName`.'

        def initialize(token)
          super(format(MSG, badge: token))
        end
      end

      attr_reader :department, :rule_name

      def self.for(class_name)
        new(*class_name.split('::').last(2))
      end

      def self.parse(identifier)
        parts = identifier.split('/', 2)

        raise InvalidBadge, identifier if parts.size > 2

        if parts.one?
          new(nil, *parts)
        else
          new(*parts)
        end
      end

      def initialize(department, rule_name)
        @department = department.to_sym if department
        @rule_name   = rule_name
      end

      def ==(other)
        hash == other.hash
      end
      alias eql? ==

      def hash
        [department, rule_name].hash
      end

      def match?(other)
        rule_name == other.rule_name &&
          (!qualified? || department == other.department)
      end

      def to_s
        qualified? ? "#{department}/#{rule_name}" : rule_name
      end

      def qualified?
        !department.nil?
      end

      def with_department(department)
        self.class.new(department, rule_name)
      end
    end
  end
end
