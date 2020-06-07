# frozen_string_literal: true

require 'tempfile'

# This module provides methods that make it easier to test Rules.
module RuleHelper
  extend RSpec::SharedContext

  let(:ruby_version) { 2.4 }
  let(:rails_version) { false }

  def inspect_source_file(source)
    Tempfile.open('tmp') { |f| inspect_source(source, f) }
  end

  def inspect_source(source, file = nil)
    RuboCop::Formatter::DisabledConfigFormatter.config_to_allow_offenses = {}
    RuboCop::Formatter::DisabledConfigFormatter.detected_styles = {}
    processed_source = parse_source(source, file)
    raise 'Error parsing example code' unless processed_source.valid_syntax?

    _investigate(rule, processed_source)
  end

  def parse_source(source, file = nil)
    if file&.respond_to?(:write)
      file.write(source)
      file.rewind
      file = file.path
    end

    RuboCop::ProcessedSource.new(source, ruby_version, file)
  end

  def autocorrect_source_file(source)
    Tempfile.open('tmp') { |f| autocorrect_source(source, f) }
  end

  def autocorrect_source(source, file = nil)
    RuboCop::Formatter::DisabledConfigFormatter.config_to_allow_offenses = {}
    RuboCop::Formatter::DisabledConfigFormatter.detected_styles = {}
    rule.instance_variable_get(:@options)[:auto_correct] = true
    processed_source = parse_source(source, file)
    _investigate(rule, processed_source)

    corrector =
      RuboCop::Rule::Corrector.new(processed_source.buffer, rule.corrections)
    corrector.rewrite
  end

  def _investigate(rule, processed_source)
    team = RuboCop::Rule::Team.new([rule], nil, raise_error: true)
    team.inspect_file(processed_source)
  end
end

module RuboCop
  module Rule
    # Monkey-patch Rule for tests to provide easy access to messages and
    # highlights.
    class Rule
      def messages
        offenses.sort.map(&:message)
      end

      def highlights
        offenses.sort.map { |o| o.location.source }
      end
    end
  end
end
