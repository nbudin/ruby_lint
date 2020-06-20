# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Shows the given rules, or all rules by default, and their configurations
      # for the current directory.
      class ShowRules < Base
        self.command_name = :show_rules

        def initialize(env)
          super

          # Load the configs so the require()s are done for custom rules
          @config = @config_store.for(Dir.pwd)
        end

        def run
          print_available_rules
        end

        private

        def print_available_rules
          registry = Cop::Cop.registry
          show_all = @options[:show_rules].empty?

          if show_all
            puts "# Available rules (#{registry.length}) " \
                 "+ config for #{Dir.pwd}: "
          end

          registry.departments.sort!.each do |department|
            print_rules_of_department(registry, department, show_all)
          end
        end

        def print_rules_of_department(registry, department, show_all)
          selected_rules = if show_all
                            rules_of_department(registry, department)
                          else
                            selected_rules_of_department(registry, department)
                          end

          puts "# Department '#{department}' (#{selected_rules.length}):" if show_all

          print_rule_details(selected_rules)
        end

        def print_rule_details(rules)
          rules.each do |rule|
            puts '# Supports --auto-correct' if rule.new(@config).support_autocorrect?
            puts "#{rule.rule_name}:"
            puts config_lines(rule)
            puts
          end
        end

        def selected_rules_of_department(rules, department)
          rules_of_department(rules, department).select do |rule|
            @options[:show_rules].include?(rule.rule_name)
          end
        end

        def rules_of_department(rules, department)
          rules.with_department(department).sort!
        end

        def config_lines(rule)
          cnf = @config.for_rule(rule)
          cnf.to_yaml.lines.to_a.drop(1).map { |line| '  ' + line }
        end
      end
    end
  end
end
