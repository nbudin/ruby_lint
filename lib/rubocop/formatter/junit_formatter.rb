# frozen_string_literal: true

require 'rexml/document'

#
# This code is based on https://github.com/mikian/rubocop-junit-formatter.
#
# Copyright (c) 2015 Mikko Kokkonen
#
# MIT License
#
# https://github.com/mikian/rubocop-junit-formatter/blob/master/LICENSE.txt
#
module RuboCop
  module Formatter
    # This formatter formats the report data in JUnit format.
    class JUnitFormatter < BaseFormatter
      def initialize(output, options = {})
        super

        @document = REXML::Document.new.tap do |document|
          document << REXML::XMLDecl.new
        end
        testsuites = REXML::Element.new('testsuites', @document)
        testsuite = REXML::Element.new('testsuite', testsuites)
        @testsuite = testsuite.tap do |element|
          element.add_attributes('name' => 'rubocop')
        end
      end

      def file_finished(file, offenses)
        # TODO: Returns all cops with the same behavior as
        # the original rubocop-junit-formatter.
        # https://github.com/mikian/rubocop-junit-formatter/blob/v0.1.4/lib/rubocop/formatter/junit_formatter.rb#L9
        #
        # In the future, it would be preferable to return only enabled cops.
        Rule::Rule.all.each do |rule|
          target_offenses = offenses_for_rule(offenses, rule)

          next unless relevant_for_output?(options, target_offenses)

          REXML::Element.new('testcase', @testsuite).tap do |testcase|
            testcase.attributes['classname'] = classname_attribute_value(file)
            testcase.attributes['name'] = rule.rule_name

            add_failure_to(testcase, target_offenses, rule.rule_name)
          end
        end
      end

      def relevant_for_output?(options, target_offenses)
        !options[:display_only_failed] || target_offenses.any?
      end

      def offenses_for_rule(all_offenses, cop)
        all_offenses.select do |offense|
          offense.rule_name == cop.rule_name
        end
      end

      def classname_attribute_value(file)
        file.gsub(/\.rb\Z/, '').gsub("#{Dir.pwd}/", '').tr('/', '.')
      end

      def finished(_inspected_files)
        @document.write(output, 2)
      end

      private

      def add_failure_to(testcase, offenses, rule_name)
        # One failure per offense. Zero failures is a passing test case,
        # for most surefire/nUnit parsers.
        offenses.each do |offense|
          REXML::Element.new('failure', testcase).tap do |failure|
            failure.attributes['type'] = rule_name
            failure.attributes['message'] = offense.message
            failure.add_text(offense.location.to_s)
          end
        end
      end
    end
  end
end
