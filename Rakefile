# frozen_string_literal: true

# For code coverage measurements to work properly, `SimpleCov` should be loaded
# and started before any application code is loaded.
require 'simplecov' if ENV['COVERAGE']

require 'bundler'
require 'bundler/gem_tasks'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'
require 'rubocop/rake_task'

Dir['tasks/**/*.rake'].each { |t| load t }

desc 'Run RuboCop over itself'
RuboCop::RakeTask.new(:internal_investigation).tap do |task|
  if RUBY_ENGINE == 'ruby' &&
     RbConfig::CONFIG['host_os'] !~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    task.options = %w[--parallel]
  end
end

task default: %i[
  documentation_syntax_check generate_cops_documentation
  spec ascii_spec
  internal_investigation
]

require 'yard'
YARD::Rake::YardocTask.new

desc 'Benchmark a cop on given source file/dir'
task :bench_cop, %i[cop srcpath times] do |_task, args|
  require 'benchmark'
  require 'rubocop'
  include RuboCop
  include RuboCop::Formatter::TextUtil

  rule_name = args[:cop]
  src_path = args[:srcpath]
  iterations = args[:times] ? Integer(args[:times]) : 1

  rule_class = if rule_name.include?('/')
                Cop::Cop.all.find { |klass| klass.rule_name == rule_name }
              else
                Cop::Cop.all.find do |klass|
                  klass.rule_name[/[a-zA-Z]+$/] == rule_name
                end
              end
  raise "No such cop: #{rule_name}" if rule_class.nil?

  config = ConfigLoader.load_file(ConfigLoader::DEFAULT_FILE)
  cop = rule_class.new(config)

  puts "Benchmarking #{cop.rule_name} on #{src_path} (using default config)"

  files = if File.directory?(src_path)
            Dir[File.join(src_path, '**', '*.rb')]
          else
            [src_path]
          end

  puts "(#{pluralize(iterations, 'iteration')}, " \
    "#{pluralize(files.size, 'file')})"

  ruby_version = RuboCop::TargetRuby.supported_versions.last
  srcs = files.map { |file| ProcessedSource.from_file(file, ruby_version) }

  puts 'Finished parsing source, testing inspection...'
  puts(Benchmark.measure do
    iterations.times do
      commissioner = Cop::Commissioner.new([cop], [])
      srcs.each { |src| commissioner.investigate(src) }
    end
  end)
end

desc 'Syntax check for the documentation comments'
task documentation_syntax_check: :yard_for_generate_documentation do
  require 'parser/ruby25'
  require 'parser/ruby26'
  require 'parser/ruby27'

  ok = true
  YARD::Registry.load!
  rules = RuboCop::Rule::Rule.registry
  rules.each do |rule|
    next if %i[RSpec Capybara FactoryBot].include?(rule.department)

    examples = YARD::Registry.all(:class).find do |code_object|
      next unless RuboCop::Rule::Badge.for(code_object.to_s) == rule.badge

      break code_object.tags('example')
    end

    examples.each do |example|
      begin
        buffer = Parser::Source::Buffer.new('<code>', 1)
        buffer.source = example.text

        # Ruby 2.6 or higher does not support a syntax used in
        # `Lint/UselessElseWithoutRescue` rule's example.
        parser = if rule == RuboCop::Rule::Lint::UselessElseWithoutRescue
                   Parser::Ruby25.new(RuboCop::AST::Builder.new)
                 # Ruby 2.7 raises an syntax error in
                 # `Lint/CircularArgumentReference` rule's example.
                 elsif rule == RuboCop::Rule::Lint::CircularArgumentReference
                   Parser::Ruby26.new(RuboCop::AST::Builder.new)
                 else
                   Parser::Ruby27.new(RuboCop::AST::Builder.new)
                 end
        parser.diagnostics.all_errors_are_fatal = true
        parser.parse(buffer)
      rescue Parser::SyntaxError => e
        path = example.object.file
        puts "#{path}: Syntax Error in an example. #{e}"
        ok = false
      end
    end
  end
  abort unless ok
end
