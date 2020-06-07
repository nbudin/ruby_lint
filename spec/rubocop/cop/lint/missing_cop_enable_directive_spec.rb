# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Lint::MissingCopEnableDirective, :config do
  context 'when the maximum range size is infinite' do
    let(:rule_config) { { 'MaximumRangeSize' => Float::INFINITY } }

    it 'registers an offense when a cop is disabled and never re-enabled' do
      expect_offense(<<~RUBY)
        # rubocop:disable Layout/SpaceAroundOperators
        ^ Re-enable Layout/SpaceAroundOperators cop with `# rubocop:enable` after disabling it.
        x =   0
        # Some other code
      RUBY
    end

    it 'does not register an offense when the disable cop is re-enabled' do
      expect_no_offenses(<<~RUBY)
        # rubocop:disable Layout/SpaceAroundOperators
        x =   0
        # rubocop:enable Layout/SpaceAroundOperators
        # Some other code
      RUBY
    end
  end

  context 'when the maximum range size is finite' do
    let(:rule_config) { { 'MaximumRangeSize' => 2 } }

    it 'registers an offense when a cop is disabled for too many lines' do
      expect_offense(<<~RUBY)
        # rubocop:disable Layout/SpaceAroundOperators
        ^ Re-enable Layout/SpaceAroundOperators cop within 2 lines after disabling it.
        x =   0
        y = 1
        # Some other code
        # rubocop:enable Layout/SpaceAroundOperators
      RUBY
    end

    it 'registers an offense when a cop is disabled and never re-enabled' do
      expect_offense(<<~RUBY)
        # rubocop:disable Layout/SpaceAroundOperators
        ^ Re-enable Layout/SpaceAroundOperators cop within 2 lines after disabling it.
        x =   0
        # Some other code
      RUBY
    end

    it 'does not register an offense when the disable cop is re-enabled ' \
       'within the limit' do
      expect_no_offenses(<<~RUBY)
        # rubocop:disable Layout/SpaceAroundOperators
        x =   0
        y = 1
        # rubocop:enable Layout/SpaceAroundOperators
        # Some other code
      RUBY
    end
  end
end
