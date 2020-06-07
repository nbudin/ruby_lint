# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

RSpec.shared_context 'isolated environment', :isolated_environment do
  around do |example|
    Dir.mktmpdir do |tmpdir|
      original_home = ENV['HOME']
      original_xdg_config_home = ENV['XDG_CONFIG_HOME']

      # Make sure to expand all symlinks in the path first. Otherwise we may
      # get mismatched pathnames when loading config files later on.
      tmpdir = File.realpath(tmpdir)

      # Make upwards search for .rubocop.yml files stop at this directory.
      RuboCop::FileFinder.root_level = tmpdir

      begin
        virtual_home = File.expand_path(File.join(tmpdir, 'home'))
        Dir.mkdir(virtual_home)
        ENV['HOME'] = virtual_home
        ENV.delete('XDG_CONFIG_HOME')

        working_dir = File.join(tmpdir, 'work')
        Dir.mkdir(working_dir)

        RuboCop::PathUtil.chdir(working_dir) do
          example.run
        end
      ensure
        ENV['HOME'] = original_home
        ENV['XDG_CONFIG_HOME'] = original_xdg_config_home

        RuboCop::FileFinder.root_level = nil
      end
    end
  end
end

# This context assumes nothing and defines `rule`, among others.
RSpec.shared_context 'config', :config do # rubocop:disable Metrics/BlockLength
  ### Meant to be overridden at will

  let(:source) { 'code = {some: :ruby}' }

  let(:rule_class) do
    if described_class.is_a?(Class) && described_class < RuboCop::Rule::Rule
      described_class
    else
      RuboCop::Rule::Rule
    end
  end

  let(:rule_config) { {} }

  let(:other_rules) { {} }

  let(:rule_options) { {} }

  ### Utilities

  def source_range(range, buffer: source_buffer)
    Parser::Source::Range.new(buffer, range.begin,
                              range.exclude_end? ? range.end : range.end + 1)
  end

  ### Useful intermediary steps (less likely to be overridden)

  let(:processed_source) { parse_source(source, 'test') }

  let(:source_buffer) { processed_source.buffer }

  let(:all_rules_config) do
    rails = { 'TargetRubyVersion' => ruby_version }
    rails['TargetRailsVersion'] = rails_version if rails_version
    rails
  end

  let(:cur_rule_config) do
    RuboCop::ConfigLoader
      .default_configuration.for_rule(rule_class)
      .merge({
               'Enabled' => true, # in case it is 'pending'
               'AutoCorrect' => true # in case defaults set it to false
             })
      .merge(rule_config)
  end

  let(:config) do
    hash = { 'AllRules' => all_rules_config,
             rule_class.rule_name => cur_rule_config }.merge!(other_rules)

    RuboCop::Config.new(hash, "#{Dir.pwd}/.rubocop.yml")
  end

  let(:rule) do
    rule_class.new(config, rule_options)
             .tap { |rule| rule.processed_source = processed_source }
  end
end

RSpec.shared_context 'mock console output' do
  before do
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  after do
    $stdout = STDOUT
    $stderr = STDERR
  end
end

RSpec.shared_context 'ruby 2.4', :ruby24 do
  let(:ruby_version) { 2.4 }
end

RSpec.shared_context 'ruby 2.5', :ruby25 do
  let(:ruby_version) { 2.5 }
end

RSpec.shared_context 'ruby 2.6', :ruby26 do
  let(:ruby_version) { 2.6 }
end

RSpec.shared_context 'ruby 2.7', :ruby27 do
  let(:ruby_version) { 2.7 }
end
