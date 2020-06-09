# frozen_string_literal: true

module RuboCop
  # This class handles obsolete configuration.
  class ConfigObsoletion
    RENAMED_RULES = {
      'Layout/AlignArguments' => 'Layout/ArgumentAlignment',
      'Layout/AlignArray' => 'Layout/ArrayAlignment',
      'Layout/AlignHash' => 'Layout/HashAlignment',
      'Layout/AlignParameters' => 'Layout/ParameterAlignment',
      'Layout/IndentArray' => 'Layout/FirstArrayElementIndentation',
      'Layout/IndentAssignment' => 'Layout/AssignmentIndentation',
      'Layout/IndentFirstArgument' => 'Layout/FirstArgumentIndentation',
      'Layout/IndentFirstArrayElement' => 'Layout/FirstArrayElementIndentation',
      'Layout/IndentFirstHashElement' => 'Layout/FirstHashElementIndentation',
      'Layout/IndentFirstParameter' => 'Layout/FirstParameterIndentation',
      'Layout/IndentHash' => 'Layout/FirstHashElementIndentation',
      'Layout/IndentHeredoc' => 'Layout/HeredocIndentation',
      'Layout/LeadingBlankLines' => 'Layout/LeadingEmptyLines',
      'Layout/Tab' => 'Layout/IndentationStyle',
      'Layout/TrailingBlankLines' => 'Layout/TrailingEmptyLines',
      'Lint/DuplicatedKey' => 'Lint/DuplicateHashKey',
      'Lint/EndInMethod' => 'Style/EndBlock',
      'Lint/HandleExceptions' => 'Lint/SuppressedException',
      'Lint/MultipleCompare' => 'Lint/MultipleComparison',
      'Lint/StringConversionInInterpolation' => 'Lint/RedundantStringCoercion',
      'Lint/UnneededCopDisableDirective' => 'Lint/RedundantCopDisableDirective',
      'Lint/UnneededCopEnableDirective' => 'Lint/RedundantCopEnableDirective',
      'Lint/UnneededRequireStatement' => 'Lint/RedundantRequireStatement',
      'Lint/UnneededSplatExpansion' => 'Lint/RedundantSplatExpansion',
      'Naming/UncommunicativeBlockParamName' => 'Naming/BlockParameterName',
      'Naming/UncommunicativeMethodParamName' => 'Naming/MethodParameterName',
      'Style/DeprecatedHashMethods' => 'Style/PreferredHashMethods',
      'Style/MethodCallParentheses' => 'Style/MethodCallWithoutArgsParentheses',
      'Style/OpMethod' => 'Naming/BinaryOperatorParameterName',
      'Style/SingleSpaceBeforeFirstArg' => 'Layout/SpaceBeforeFirstArg',
      'Style/UnneededCapitalW' => 'Style/RedundantCapitalW',
      'Style/UnneededCondition' => 'Style/RedundantCondition',
      'Style/UnneededInterpolation' => 'Style/RedundantInterpolation',
      'Style/UnneededPercentQ' => 'Style/RedundantPercentQ',
      'Style/UnneededSort' => 'Style/RedundantSort'
    }.map do |old_name, new_name|
      [old_name, "The `#{old_name}` rule has been renamed to `#{new_name}`."]
    end

    MOVED_RULES = {
      'Security' => 'Lint/Eval',
      'Naming' => %w[Style/ClassAndModuleCamelCase Style/ConstantName
                     Style/FileName Style/MethodName Style/PredicateName
                     Style/VariableName Style/VariableNumber
                     Style/AccessorMethodName Style/AsciiIdentifiers],
      'Layout' => %w[Lint/BlockAlignment Lint/EndAlignment
                     Lint/DefEndAlignment Metrics/LineLength],
      'Lint' => 'Style/FlipFlop'
    }.map do |new_department, old_names|
      Array(old_names).map do |old_name|
        [old_name, "The `#{old_name}` rule has been moved to " \
                   "`#{new_department}/#{old_name.split('/').last}`."]
      end
    end

    REMOVED_RULES = {
      'Layout/SpaceAfterControlKeyword' => 'Layout/SpaceAroundKeyword',
      'Layout/SpaceBeforeModifierKeyword' => 'Layout/SpaceAroundKeyword',
      'Lint/RescueWithoutErrorClass' => 'Style/RescueStandardError',
      'Rails/DefaultScope' => nil,
      'Style/SpaceAfterControlKeyword' => 'Layout/SpaceAroundKeyword',
      'Style/SpaceBeforeModifierKeyword' => 'Layout/SpaceAroundKeyword',
      'Style/TrailingComma' => 'Style/TrailingCommaInArguments, ' \
                               'Style/TrailingCommaInArrayLiteral, and/or ' \
                               'Style/TrailingCommaInHashLiteral',
      'Style/TrailingCommaInLiteral' => 'Style/TrailingCommaInArrayLiteral ' \
                                        'and/or ' \
                                        'Style/TrailingCommaInHashLiteral',
      'Style/BracesAroundHashParameters' => nil
    }.map do |old_name, other_rules|
      if other_rules
        more = ". Please use #{other_rules} instead".gsub(%r{[A-Z]\w+/\w+},
                                                         '`\&`')
      end
      [old_name, "The `#{old_name}` rule has been removed#{more}."]
    end

    REMOVED_RULES_WITH_REASON = {
      'Lint/InvalidCharacterLiteral' => 'it was never being actually triggered',
      'Lint/SpaceBeforeFirstArg' =>
        'it was a duplicate of `Layout/SpaceBeforeFirstArg`. Please use ' \
        '`Layout/SpaceBeforeFirstArg` instead'
    }.map do |rule_name, reason|
      [rule_name, "The `#{rule_name}` rule has been removed since #{reason}."]
    end

    SPLIT_RULES = {
      'Style/MethodMissing' =>
        'The `Style/MethodMissing` rule has been split into ' \
        '`Style/MethodMissingSuper` and `Style/MissingRespondToMissing`.'
    }.to_a

    OBSOLETE_RULES = Hash[*(RENAMED_RULES + MOVED_RULES + REMOVED_RULES +
                           REMOVED_RULES_WITH_REASON + SPLIT_RULES).flatten]

    OBSOLETE_PARAMETERS = [
      {
        rule: %w[Layout/SpaceAroundOperators Style/SpaceAroundOperators],
        parameters: 'MultiSpaceAllowedForOperators',
        alternative: 'If your intention was to allow extra spaces for ' \
                     'alignment, please use AllowForAlignment: true instead.'
      },
      {
        rule: 'Style/Encoding',
        parameters: %w[EnforcedStyle SupportedStyles
                       AutoCorrectEncodingComment],
        alternative: 'Style/Encoding no longer supports styles. ' \
                     'The "never" behavior is always assumed.'
      },
      {
        rule: 'Style/IfUnlessModifier',
        parameters: 'MaxLineLength',
        alternative: '`Style/IfUnlessModifier: MaxLineLength` has been ' \
                     'removed. Use `Layout/LineLength: Max` instead'
      },
      {
        rule: 'Style/WhileUntilModifier',
        parameters: 'MaxLineLength',
        alternative: '`Style/WhileUntilModifier: MaxLineLength` has been ' \
                     'removed. Use `Layout/LineLength: Max` instead'
      },
      {
        rule: 'AllRules',
        parameters: 'RunRailsCops',
        alternative: "Use the following configuration instead:\n" \
                     "Rails:\n  Enabled: true"
      },
      {
        rule: 'Layout/CaseIndentation',
        parameters: 'IndentWhenRelativeTo',
        alternative: '`IndentWhenRelativeTo` has been renamed to ' \
                     '`EnforcedStyle`'
      },
      {
        rule: %w[Lint/BlockAlignment Layout/BlockAlignment Lint/EndAlignment
                 Layout/EndAlignment Lint/DefEndAlignment
                 Layout/DefEndAlignment],
        parameters: 'AlignWith',
        alternative: '`AlignWith` has been renamed to `EnforcedStyleAlignWith`'
      },
      {
        rule: 'Rails/UniqBeforePluck',
        parameters: 'EnforcedMode',
        alternative: '`EnforcedMode` has been renamed to `EnforcedStyle`'
      },
      {
        rule: 'Style/MethodCallWithArgsParentheses',
        parameters: 'IgnoredMethodPatterns',
        alternative: '`IgnoredMethodPatterns` has been renamed to ' \
                     '`IgnoredPatterns`'
      },
      {
        rule: %w[Performance/Count Performance/Detect],
        parameters: 'SafeMode',
        alternative: '`SafeMode` has been removed. ' \
                     'Use `SafeAutoCorrect` instead.'
      },
      {
        rule: 'Bundler/GemComment',
        parameters: 'Whitelist',
        alternative: '`Whitelist` has been renamed to `IgnoredGems`.'
      },
      {
        rule: %w[
          Lint/SafeNavigationChain Lint/SafeNavigationConsistency
          Style/NestedParenthesizedCalls Style/SafeNavigation
          Style/TrivialAccessors
        ],
        parameters: 'Whitelist',
        alternative: '`Whitelist` has been renamed to `AllowedMethods`.'
      },
      {
        rule: 'Style/IpAddresses',
        parameters: 'Whitelist',
        alternative: '`Whitelist` has been renamed to `AllowedAddresses`.'
      },
      {
        rule: 'Naming/HeredocDelimiterNaming',
        parameters: 'Blacklist',
        alternative: '`Blacklist` has been renamed to `ForbiddenDelimiters`.'
      },
      {
        rule: 'Naming/PredicateName',
        parameters: 'NamePrefixBlacklist',
        alternative: '`NamePrefixBlacklist` has been renamed to ' \
                     '`ForbiddenPrefixes`.'
      },
      {
        rule: 'Naming/PredicateName',
        parameters: 'NameWhitelist',
        alternative: '`NameWhitelist` has been renamed to ' \
                     '`AllowedMethods`.'
      }
    ].freeze

    OBSOLETE_ENFORCED_STYLES = [
      {
        rule: 'Layout/IndentationConsistency',
        parameter: 'EnforcedStyle',
        enforced_style: 'rails',
        alternative: '`EnforcedStyle: rails` has been renamed to ' \
                     '`EnforcedStyle: indented_internal_methods`'
      }
    ].freeze

    def initialize(config)
      @config = config
    end

    def reject_obsolete_rules_and_parameters
      messages = [obsolete_rules, obsolete_parameters,
                  obsolete_enforced_style].flatten.compact
      return if messages.empty?

      raise ValidationError, messages.join("\n")
    end

    private

    def obsolete_rules
      OBSOLETE_RULES.map do |rule_name, message|
        next unless @config.key?(rule_name) ||
                    @config.key?(Rule::Badge.parse(rule_name).rule_name)

        message + "\n(obsolete configuration found in " \
                  "#{smart_loaded_path}, please update it)"
      end
    end

    def obsolete_enforced_style
      OBSOLETE_ENFORCED_STYLES.map do |params|
        obsolete_enforced_style_message(params[:rule], params[:parameter],
                                        params[:enforced_style],
                                        params[:alternative])
      end
    end

    def obsolete_enforced_style_message(rule, param, enforced_style, alternative)
      style = @config[rule]&.detect { |key, _| key.start_with?(param) }

      return unless style && style[1] == enforced_style

      "obsolete `#{param}: #{enforced_style}` (for #{rule}) found in " \
      "#{smart_loaded_path}\n#{alternative}"
    end

    def obsolete_parameters
      OBSOLETE_PARAMETERS.map do |params|
        obsolete_parameter_message(params[:rules], params[:parameters],
                                   params[:alternative])
      end
    end

    def obsolete_parameter_message(rules, parameters, alternative)
      Array(rules).map do |rule|
        obsolete_parameters = Array(parameters).select do |param|
          @config[rule]&.key?(param)
        end
        next if obsolete_parameters.empty?

        obsolete_parameters.map do |parameter|
          "obsolete parameter #{parameter} (for #{rule}) found in " \
          "#{smart_loaded_path}\n#{alternative}"
        end
      end
    end

    def smart_loaded_path
      PathUtil.smart_path(@config.loaded_path)
    end
  end
end
