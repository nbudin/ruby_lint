# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Style::MissingElse do
  subject(:cop) { described_class.new(config) }

  context 'UnlessElse enabled' do
    let(:config) do
      RuboCop::Config.new('Style/MissingElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'both',
                            'SupportedStyles' => %w[if case both]
                          },
                          'Style/UnlessElse' => { 'Enabled' => true })
    end

    context 'given an if-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo elsif b; bar else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            if cond; foo end
            ^^^^^^^^^^^^^^^^ `if` condition requires an `else`-clause.
          RUBY
        end
      end
    end

    context 'given an unless-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo end')
        end
      end
    end

    context 'given a case statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; else b; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            case v; when a; foo; when b; bar; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `case` condition requires an `else`-clause.
          RUBY
        end
      end
    end
  end

  context 'UnlessElse disabled' do
    let(:config) do
      RuboCop::Config.new('Style/MissingElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'both',
                            'SupportedStyles' => %w[if case both]
                          },
                          'Style/UnlessElse' => { 'Enabled' => false })
    end

    context 'given an if-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo elsif b; bar else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            if cond; foo end
            ^^^^^^^^^^^^^^^^ `if` condition requires an `else`-clause.
          RUBY
        end
      end
    end

    context 'given an unless-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            unless cond; foo end
            ^^^^^^^^^^^^^^^^^^^^ `if` condition requires an `else`-clause.
          RUBY
        end
      end
    end

    context 'given a case statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; else b; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            case v; when a; foo; when b; bar; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `case` condition requires an `else`-clause.
          RUBY
        end
      end
    end
  end

  context 'EmptyElse enabled and set to warn on empty' do
    let(:config) do
      styles = %w[if case both]
      RuboCop::Config.new('Style/MissingElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'both',
                            'SupportedStyles' => styles
                          },
                          'Style/UnlessElse' => { 'Enabled' => false },
                          'Style/EmptyElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'empty',
                            'SupportedStyles' => %w[empty nil both]
                          })
    end

    context 'given an if-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo elsif b; bar else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            if cond; foo end
            ^^^^^^^^^^^^^^^^ `if` condition requires an `else`-clause with `nil` in it.
          RUBY
        end
      end
    end

    context 'given an unless-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            unless cond; foo end
            ^^^^^^^^^^^^^^^^^^^^ `if` condition requires an `else`-clause with `nil` in it.
          RUBY
        end
      end
    end

    context 'given a case statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; else b; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            case v; when a; foo; when b; bar; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `case` condition requires an `else`-clause with `nil` in it.
          RUBY
        end
      end
    end
  end

  context 'EmptyElse enabled and set to warn on nil' do
    let(:config) do
      styles = %w[if case both]
      RuboCop::Config.new('Style/MissingElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'both',
                            'SupportedStyles' => styles
                          },
                          'Style/UnlessElse' => { 'Enabled' => false },
                          'Style/EmptyElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'nil',
                            'SupportedStyles' => %w[empty nil both]
                          })
    end

    context 'given an if-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo elsif b; bar else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            if cond; foo end
            ^^^^^^^^^^^^^^^^ `if` condition requires an empty `else`-clause.
          RUBY
        end
      end
    end

    context 'given an unless-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            unless cond; foo end
            ^^^^^^^^^^^^^^^^^^^^ `if` condition requires an empty `else`-clause.
          RUBY
        end
      end
    end

    context 'given a case statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; else b; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            case v; when a; foo; when b; bar; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `case` condition requires an empty `else`-clause.
          RUBY
        end
      end
    end
  end

  context 'configured to warn only on empty if' do
    let(:config) do
      styles = %w[if case both]
      RuboCop::Config.new('Style/MissingElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'if',
                            'SupportedStyles' => styles
                          },
                          'Style/UnlessElse' => { 'Enabled' => false },
                          'Style/EmptyElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'nil',
                            'SupportedStyles' => %w[empty nil both]
                          })
    end

    context 'given an if-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo elsif b; bar else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            if cond; foo end
            ^^^^^^^^^^^^^^^^ `if` condition requires an empty `else`-clause.
          RUBY
        end
      end
    end

    context 'given an unless-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            unless cond; foo end
            ^^^^^^^^^^^^^^^^^^^^ `if` condition requires an empty `else`-clause.
          RUBY
        end
      end
    end

    context 'given a case statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; else b; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; end')
        end
      end
    end
  end

  context 'configured to warn only on empty case' do
    let(:config) do
      styles = %w[if case both]
      RuboCop::Config.new('Style/MissingElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'case',
                            'SupportedStyles' => styles
                          },
                          'Style/UnlessElse' => { 'Enabled' => false },
                          'Style/EmptyElse' => {
                            'Enabled' => true,
                            'EnforcedStyle' => 'nil',
                            'SupportedStyles' => %w[empty nil both]
                          })
    end

    context 'given an if-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('if a; foo elsif b; bar else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('if cond; foo end')
        end
      end
    end

    context 'given an unless-statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo else bar; nil end')
        end
      end

      context 'with no else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('unless cond; foo end')
        end
      end
    end

    context 'given a case statement' do
      context 'with a completely empty else-clause' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo else end')
        end
      end

      context 'with an else-clause containing only the literal nil' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; when b; bar; else nil end')
        end
      end

      context 'with an else-clause with side-effects' do
        it "doesn't register an offense" do
          expect_no_offenses('case v; when a; foo; else b; nil end')
        end
      end

      context 'with no else-clause' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            case v; when a; foo; when b; bar; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `case` condition requires an empty `else`-clause.
          RUBY
        end
      end
    end
  end
end
