# frozen_string_literal: true

require 'rubocop'

desc 'Generate a new rule template'
task :new_rule, [:rule] do |_task, args|
  rule_name = args.fetch(:rule) do
    warn 'usage: bundle exec rake new_rule[Department/Name]'
    exit!
  end

  github_user = `git config github.user`.chop
  github_user = 'your_id' if github_user.empty?

  generator = RuboCop::Rule::Generator.new(rule_name, github_user)

  generator.write_source
  generator.write_spec
  generator.inject_require
  generator.inject_config

  puts generator.todo
end
