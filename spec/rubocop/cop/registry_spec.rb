# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Registry do
  subject(:registry) { described_class.new(cops, options) }

  let(:cops) do
    [
      RuboCop::Rule::Lint::BooleanSymbol,
      RuboCop::Rule::Lint::DuplicateMethods,
      RuboCop::Rule::Layout::FirstArrayElementIndentation,
      RuboCop::Rule::Metrics::MethodLength,
      RuboCop::Rule::RSpec::Foo,
      RuboCop::Rule::Test::FirstArrayElementIndentation
    ]
  end

  let(:options) { {} }

  before do
    stub_const('RuboCop::Rule::Test::FirstArrayElementIndentation', Class.new(RuboCop::Rule::Rule))
    stub_const('RuboCop::Rule::RSpec::Foo', Class.new(RuboCop::Rule::Rule))
  end

  # `RuboCop::Rule::Rule` mutates its `registry` when inherited from.
  # This can introduce nondeterministic failures in other parts of the
  # specs if this mutation occurs before code that depends on this global cop
  # store. The workaround is to replace the global cop store with a temporary
  # store during these tests
  around do |test|
    described_class.with_temporary_global { test.run }
  end

  it 'can be cloned' do
    klass = ::RuboCop::Rule::Metrics::AbcSize
    copy = registry.dup
    copy.enlist(klass)
    expect(copy.cops).to include(klass)
    expect(registry.cops).not_to include(klass)
  end

  context 'when dismissing a cop class' do
    let(:rule_class) { ::RuboCop::Rule::Metrics::AbcSize }

    before { registry.enlist(rule_class) }

    it 'allows it if done rapidly' do
      registry.dismiss(rule_class)
      expect(registry.cops).not_to include(rule_class)
    end

    it 'disallows it if done too late' do
      expect(registry.cops).to include(rule_class)
      expect { registry.dismiss(rule_class) }.to raise_error(RuntimeError)
    end

    it 'allows re-listing' do
      registry.dismiss(rule_class)
      expect(registry.cops).not_to include(rule_class)
      registry.enlist(rule_class)
      expect(registry.cops).to include(rule_class)
    end
  end

  it 'exposes cop departments' do
    expect(registry.departments).to eql(%i[Lint Layout Metrics RSpec Test])
  end

  it 'can filter down to one type' do
    expect(registry.with_department(:Lint))
      .to eq(described_class.new(cops.first(2)))
  end

  it 'can filter down to all but one type' do
    expect(registry.without_department(:Lint))
      .to eq(described_class.new(cops.drop(2)))
  end

  describe '#contains_cop_matching?' do
    it 'can find cops matching a given name' do
      result = registry.contains_cop_matching?(
        ['Test/FirstArrayElementIndentation']
      )
      expect(result).to be(true)
    end

    it 'returns false for cops not included in the store' do
      expect(registry.contains_cop_matching?(['Style/NotReal'])).to be(false)
    end
  end

  describe '#qualified_rule_name' do
    let(:origin) { '/app/.rubocop.yml' }

    it 'gives back already properly qualified names' do
      result = registry.qualified_rule_name(
        'Layout/FirstArrayElementIndentation',
        origin
      )
      expect(result).to eql('Layout/FirstArrayElementIndentation')
    end

    it 'qualifies names without a namespace' do
      warning =
        "/app/.rubocop.yml: Warning: no department given for MethodLength.\n"
      qualified = nil

      expect do
        qualified = registry.qualified_rule_name('MethodLength', origin)
      end.to output(warning).to_stderr

      expect(qualified).to eql('Metrics/MethodLength')
    end

    it 'qualifies names with the correct namespace' do
      warning = "/app/.rubocop.yml: Warning: no department given for Foo.\n"
      qualified = nil

      expect do
        qualified = registry.qualified_rule_name('Foo', origin)
      end.to output(warning).to_stderr

      expect(qualified).to eql('RSpec/Foo')
    end

    it 'emits a warning when namespace is incorrect' do
      warning = '/app/.rubocop.yml: Style/MethodLength has the wrong ' \
                "namespace - should be Metrics\n"
      qualified = nil

      expect do
        qualified = registry.qualified_rule_name('Style/MethodLength', origin)
      end.to output(warning).to_stderr

      expect(qualified).to eql('Metrics/MethodLength')
    end

    it 'raises an error when a cop name is ambiguous' do
      rule_name = 'FirstArrayElementIndentation'
      expect { registry.qualified_rule_name(rule_name, origin) }
        .to raise_error(RuboCop::Rule::AmbiguousCopName)
        .with_message(
          'Ambiguous cop name `FirstArrayElementIndentation` used in ' \
          '/app/.rubocop.yml needs department qualifier. Did you mean ' \
          'Layout/FirstArrayElementIndentation or ' \
          'Test/FirstArrayElementIndentation?'
        )
        .and output('/app/.rubocop.yml: Warning: no department given for ' \
                    "FirstArrayElementIndentation.\n").to_stderr
    end

    it 'returns the provided name if no namespace is found' do
      expect(registry.qualified_rule_name('NotReal', origin)).to eql('NotReal')
    end
  end

  it 'exposes a mapping of cop names to cop classes' do
    expect(registry.to_h).to eql(
      'Lint/BooleanSymbol' => [RuboCop::Rule::Lint::BooleanSymbol],
      'Lint/DuplicateMethods' => [RuboCop::Rule::Lint::DuplicateMethods],
      'Layout/FirstArrayElementIndentation' => [
        RuboCop::Rule::Layout::FirstArrayElementIndentation
      ],
      'Metrics/MethodLength' => [RuboCop::Rule::Metrics::MethodLength],
      'Test/FirstArrayElementIndentation' => [
        RuboCop::Rule::Test::FirstArrayElementIndentation
      ],
      'RSpec/Foo' => [RuboCop::Rule::RSpec::Foo]
    )
  end

  describe '#cops' do
    it 'exposes a list of cops' do
      expect(registry.cops).to eql(cops)
    end
  end

  it 'exposes the number of stored cops' do
    expect(registry.length).to be(6)
  end

  describe '#enabled' do
    let(:config) do
      RuboCop::Config.new(
        'Test/FirstArrayElementIndentation' => { 'Enabled' => false },
        'RSpec/Foo' => { 'Safe' => false }
      )
    end

    it 'selects cops which are enabled in the config' do
      expect(registry.enabled(config, [])).to eql(cops.first(5))
    end

    it 'overrides config if :only includes the cop' do
      result = registry.enabled(config, ['Test/FirstArrayElementIndentation'])
      expect(result).to eql(cops)
    end

    it 'selects only safe cops if :safe passed' do
      enabled_cops = registry.enabled(config, [], true)
      expect(enabled_cops).not_to include(RuboCop::Rule::RSpec::Foo)
    end

    context 'when new cops are introduced' do
      let(:config) do
        RuboCop::Config.new(
          'Lint/BooleanSymbol' => { 'Enabled' => 'pending' }
        )
      end

      it 'does not include them' do
        result = registry.enabled(config, [])
        expect(result).not_to include(RuboCop::Rule::Lint::BooleanSymbol)
      end

      it 'overrides config if :only includes the cop' do
        result = registry.enabled(config, ['Lint/BooleanSymbol'])
        expect(result).to eql(cops)
      end

      context 'when specifying `--disable-pending-cops` command-line option' do
        let(:options) do
          { disable_pending_cops: true }
        end

        it 'does not include them' do
          result = registry.enabled(config, [])
          expect(result).not_to include(RuboCop::Rule::Lint::BooleanSymbol)
        end

        context 'when specifying `NewRules: enable` option in .rubocop.yml' do
          let(:config) do
            RuboCop::Config.new(
              'AllRules' => { 'NewRules' => 'enable' },
              'Lint/BooleanSymbol' => { 'Enabled' => 'pending' }
            )
          end

          it 'does not include them because command-line option takes ' \
             'precedence over .rubocop.yml' do
            result = registry.enabled(config, [])
            expect(result).not_to include(RuboCop::Rule::Lint::BooleanSymbol)
          end
        end
      end

      context 'when specifying `--enable-pending-cops` command-line option' do
        let(:options) do
          { enable_pending_cops: true }
        end

        it 'includes them' do
          result = registry.enabled(config, [])
          expect(result).to include(RuboCop::Rule::Lint::BooleanSymbol)
        end

        context 'when specifying `NewRules: disable` option in .rubocop.yml' do
          let(:config) do
            RuboCop::Config.new(
              'AllRules' => { 'NewRules' => 'disable' },
              'Lint/BooleanSymbol' => { 'Enabled' => 'pending' }
            )
          end

          it 'includes them because command-line option takes ' \
             'precedence over .rubocop.yml' do
            result = registry.enabled(config, [])
            expect(result).to include(RuboCop::Rule::Lint::BooleanSymbol)
          end
        end
      end

      context 'when specifying `NewRules: pending` option in .rubocop.yml' do
        let(:config) do
          RuboCop::Config.new(
            'AllRules' => { 'NewRules' => 'pending' },
            'Lint/BooleanSymbol' => { 'Enabled' => 'pending' }
          )
        end

        it 'does not include them' do
          result = registry.enabled(config, [])
          expect(result).not_to include(RuboCop::Rule::Lint::BooleanSymbol)
        end
      end

      context 'when specifying `NewRules: disable` option in .rubocop.yml' do
        let(:config) do
          RuboCop::Config.new(
            'AllRules' => { 'NewRules' => 'disable' },
            'Lint/BooleanSymbol' => { 'Enabled' => 'pending' }
          )
        end

        it 'does not include them' do
          result = registry.enabled(config, [])
          expect(result).not_to include(RuboCop::Rule::Lint::BooleanSymbol)
        end
      end

      context 'when specifying `NewRules: enable` option in .rubocop.yml' do
        let(:config) do
          RuboCop::Config.new(
            'AllRules' => { 'NewRules' => 'enable' },
            'Lint/BooleanSymbol' => { 'Enabled' => 'pending' }
          )
        end

        it 'includes them' do
          result = registry.enabled(config, [])
          expect(result).to include(RuboCop::Rule::Lint::BooleanSymbol)
        end
      end
    end
  end

  it 'exposes a list of cop names' do
    expect(registry.names).to eql(
      [
        'Lint/BooleanSymbol',
        'Lint/DuplicateMethods',
        'Layout/FirstArrayElementIndentation',
        'Metrics/MethodLength',
        'RSpec/Foo',
        'Test/FirstArrayElementIndentation'
      ]
    )
  end
end
