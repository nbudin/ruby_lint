# frozen_string_literal: true

module RuboCop
  module Rule
    # Message Annotator class annotates a basic offense message
    # based on params passed into initializer.
    #
    # @see #initialize
    #
    # @example
    #   RuboCop::Rule::MessageAnnotator.new(
    #     config, rule_name, rule_config, @options
    #   ).annotate('message')
    #  #=> 'Cop/CopName: message (http://example.org/styleguide)'
    class MessageAnnotator
      attr_reader :options, :config, :rule_name, :rule_config

      @style_guide_urls = {}

      class << self
        attr_reader :style_guide_urls
      end

      # @param config [RuboCop::Config] Check configs for all cops
      #   @note Message Annotator specifically checks the
      #     following config options for_all_rules
      #     :StyleGuideBaseURL [String] URL for styleguide
      #     :DisplayStyleGuide [Boolean] Include styleguide and reference URLs
      #     :ExtraDetails [Boolean] Include cop details
      #     :DisplayCopNames [Boolean] Include cop name
      #
      # @param [String] rule_name for specific cop name
      # @param [Hash] rule_config configs for specific cop, from config#for_cop
      # @option rule_config [String] :StyleGuide Extension of base styleguide URL
      # @option rule_config [String] :Reference Full reference URL
      # @option rule_config [String] :Details
      #
      # @param [Hash, nil] options optional
      # @option options [Boolean] :display_style_guide
      #   Include style guide and reference URLs
      # @option options [Boolean] :extra_details
      #   Include cop specific details
      # @option options [Boolean] :debug
      #   Include debug output
      # @option options [Boolean] :display_rule_names
      #   Include cop name
      def initialize(config, rule_name, rule_config, options)
        @config = config
        @rule_name = rule_name
        @rule_config = rule_config || {}
        @options = options
      end

      # Returns the annotated message,
      # based on params passed into initializer
      #
      # @return [String] annotated message
      def annotate(message)
        message = "#{rule_name}: #{message}" if display_rule_names?
        message += " #{details}" if extra_details? && details
        if display_style_guide?
          links = urls.join(', ')
          message = "#{message} (#{links})"
        end
        message
      end

      def urls
        [style_guide_url, *reference_urls].compact
      end

      private

      def style_guide_url
        url = rule_config['StyleGuide']
        return nil if url.nil? || url.empty?

        self.class.style_guide_urls[url] ||= begin
          base_url = style_guide_base_url
          if base_url.nil? || base_url.empty?
            url
          else
            URI.join(base_url, url).to_s
          end
        end
      end

      def style_guide_base_url
        department_name = rule_name.split('/').first

        config.for_department(department_name)['StyleGuideBaseURL'] ||
          config.for_all_rules['StyleGuideBaseURL']
      end

      def display_style_guide?
        (options[:display_style_guide] ||
         config.for_all_rules['DisplayStyleGuide']) &&
          !urls.empty?
      end

      def reference_urls
        urls = Array(rule_config['Reference'])
        urls.nil? || urls.empty? ? nil : urls.reject(&:empty?)
      end

      def extra_details?
        options[:extra_details] || config.for_all_rules['ExtraDetails']
      end

      def debug?
        options[:debug]
      end

      def display_rule_names?
        return true if debug?
        return false if options[:display_rule_names] == false
        return true if options[:display_rule_names]
        return false if options[:format] == 'json'

        config.for_all_rules['DisplayRuleNames']
      end

      def details
        details = rule_config && rule_config['Details']
        details.nil? || details.empty? ? nil : details
      end
    end
  end
end
