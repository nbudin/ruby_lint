# frozen_string_literal: true

module RuboCop
  module Rule
    # Error raised when an unqualified rule name is used that could
    # refer to two or more cops under different departments
    class AmbiguousRuleName < RuboCop::Error
      MSG = 'Ambiguous rule name `%<name>s` used in %<origin>s needs ' \
            'department qualifier. Did you mean %<options>s?'

      def initialize(name, origin, badges)
        super(
          format(
            MSG,
            name: name,
            origin: origin,
            options: badges.to_a.join(' or ')
          )
        )
      end
    end

    # Registry that tracks all cops by their badge and department.
    class Registry
      include Enumerable

      attr_reader :options

      def initialize(rules = [], options = {})
        @registry = {}
        @departments = {}
        @rules_by_rule_name = Hash.new { |hash, key| hash[key] = [] }

        @enrollment_queue = rules
        @options = options
      end

      def enlist(rule)
        @enrollment_queue << rule
      end

      def dismiss(rule)
        raise "Rule #{rule} could not be dismissed" unless @enrollment_queue.delete(rule)
      end

      # @return [Array<Symbol>] list of departments for current rules.
      def departments
        clear_enrollment_queue
        @departments.keys
      end

      # @return [Registry] Rules for that specific department.
      def with_department(department)
        clear_enrollment_queue
        with(@departments.fetch(department, []))
      end

      # @return [Registry] Rules not for a specific department.
      def without_department(department)
        clear_enrollment_queue
        without_department = @departments.dup
        without_department.delete(department)

        with(without_department.values.flatten)
      end

      def contains_rule_matching?(names)
        rules.any? { |rule| rule.match?(names) }
      end

      # Convert a user provided rule name into a properly namespaced name
      #
      # @example gives back a correctly qualified rule name
      #
      #   rules = RuboCop::Rule::Rule.all
      #   rules.
      #     qualified_rule_name('Layout/EndOfLine') # => 'Layout/EndOfLine'
      #
      # @example fixes incorrect namespaces
      #
      #   rules = RuboCop::Rule::Rule.all
      #   rules.qualified_rule_name('Lint/EndOfLine') # => 'Layout/EndOfLine'
      #
      # @example namespaces bare rule identifiers
      #
      #   rules = RuboCop::Rule::Rule.all
      #   rules.qualified_rule_name('EndOfLine') # => 'Layout/EndOfLine'
      #
      # @example passes back unrecognized rule names
      #
      #   rules = RuboCop::Rule::Rule.all
      #   rules.qualified_rule_name('NotARule') # => 'NotARule'
      #
      # @param name [String] Rule name extracted from config
      # @param path [String, nil] Path of file that `name` was extracted from
      #
      # @raise [AmbiguousRuleName]
      #   if a bare identifier with two possible namespaces is provided
      #
      # @note Emits a warning if the provided name has an incorrect namespace
      #
      # @return [String] Qualified rule name
      def qualified_rule_name(name, path, shall_warn = true)
        badge = Badge.parse(name)
        print_warning(name, path) if shall_warn && department_missing?(badge, name)
        return name if registered?(badge)

        potential_badges = qualify_badge(badge)

        case potential_badges.size
        when 0 then name # No namespace found. Deal with it later in caller.
        when 1 then resolve_badge(badge, potential_badges.first, path)
        else raise AmbiguousCopName.new(badge, path, potential_badges)
        end
      end

      def department_missing?(badge, name)
        !badge.qualified? && unqualified_rule_names.include?(name)
      end

      def print_warning(name, path)
        message = "#{path}: Warning: no department given for #{name}."
        if path.end_with?('.rb')
          message += ' Run `rubocop -a --only Migration/DepartmentName` to fix.'
        end
        warn message
      end

      def unqualified_rule_names
        clear_enrollment_queue
        @unqualified_rule_names ||=
          Set.new(@rules_by_rule_name.keys.map { |qn| File.basename(qn) }) <<
          'RedundantRuleDisableDirective'
      end

      # @return [Hash{String => Array<Class>}]
      def to_h
        clear_enrollment_queue
        @rules_by_rule_name
      end

      def rules
        clear_enrollment_queue
        @registry.values
      end

      def length
        clear_enrollment_queue
        @registry.size
      end

      def enabled(config, only = [], only_safe = false)
        select do |rule|
          only.include?(rule.rule_name) || enabled?(rule, config, only_safe)
        end
      end

      def enabled?(rule, config, only_safe)
        cfg = config.for_rule(rule)

        rule_enabled = cfg.fetch('Enabled') == true ||
                      enabled_pending_rule?(cfg, config)

        if only_safe
          rule_enabled && cfg.fetch('Safe', true)
        else
          rule_enabled
        end
      end

      def enabled_pending_rule?(rule_cfg, config)
        return false if @options[:disable_pending_rules]

        rule_cfg.fetch('Enabled') == 'pending' &&
          (@options[:enable_pending_rules] || config.enabled_new_rules?)
      end

      def names
        rules.map(&:rule_name)
      end

      def ==(other)
        rules == other.rules
      end

      def sort!
        clear_enrollment_queue
        @registry = Hash[@registry.sort_by { |badge, _| badge.rule_name }]

        self
      end

      def select(&block)
        rules.select(&block)
      end

      def each(&block)
        cops.each(&block)
      end

      # @param [String] rule_name
      # @return [Class, nil]
      def find_by_rule_name(rule_name)
        to_h[rule_name].first
      end

      @global = new

      class << self
        attr_reader :global
      end

      def self.all
        global.without_department(:Test).rules
      end

      def self.qualified_rule_name(name, origin)
        global.qualified_rule_name(name, origin)
      end

      # Changes momentarily the global registry
      # Intended for testing purposes
      def self.with_temporary_global(temp_global = global.dup)
        previous = @global
        @global = temp_global
        yield
      ensure
        @global = previous
      end

      private

      def initialize_copy(reg)
        initialize(reg.rules, reg.options)
      end

      def clear_enrollment_queue
        return if @enrollment_queue.empty?

        @enrollment_queue.each do |rule|
          @registry[rule.badge] = rule
          @departments[rule.department] ||= []
          @departments[rule.department] << rule
          @rules_by_rule_name[rule.rule_name] << rule
        end
        @enrollment_queue = []
      end

      def with(rules)
        self.class.new(rules)
      end

      def qualify_badge(badge)
        clear_enrollment_queue
        @departments
          .map { |department, _| badge.with_department(department) }
          .select { |potential_badge| registered?(potential_badge) }
      end

      def resolve_badge(given_badge, real_badge, source_path)
        unless given_badge.match?(real_badge)
          path = PathUtil.smart_path(source_path)
          warn "#{path}: #{given_badge} has the wrong namespace - " \
               "should be #{real_badge.department}"
        end

        real_badge.to_s
      end

      def registered?(badge)
        clear_enrollment_queue
        @registry.key?(badge)
      end
    end
  end
end
