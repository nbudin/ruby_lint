# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::TernaryParentheses, :config do
  before do
    inspect_source(source)
  end

  let(:redundant_parens_enabled) { false }
  let(:other_cops) do
    {
      'Style/RedundantParentheses' => { 'Enabled' => redundant_parens_enabled }
    }
  end

  shared_examples 'code with offense' do |code, expected|
    context "when checking #{code}" do
      let(:source) { code }

      it 'registers an offense' do
        expect(rule.offenses.size).to eq(1)
        expect(rule.messages).to eq([message])
      end

      if expected
        it 'auto-corrects' do
          expect(autocorrect_source(code)).to eq(expected)
        end

        it 'claims to auto-correct' do
          autocorrect_source(code)
          expect(rule.offenses.last.status).to eq(:corrected)
        end
      else
        it 'does not auto-correct' do
          expect(autocorrect_source(code)).to eq(code)
        end

        it 'does not claim to auto-correct' do
          autocorrect_source(code)
          expect(rule.offenses.last.status).to eq(:uncorrected)
        end
      end
    end
  end

  shared_examples 'code without offense' do |code|
    let(:source) { code }

    it 'does not register an offense' do
      expect(rule.offenses.empty?).to be(true)
    end
  end

  shared_examples 'safe assignment disabled' do |style|
    let(:rule_config) do
      {
        'EnforcedStyle' => style,
        'AllowSafeAssignment' => false
      }
    end

    it_behaves_like 'code with offense',
                    'foo = (bar = find_bar) ? a : b'

    it_behaves_like 'code with offense',
                    'foo = bar = (baz = find_baz) ? a : b'

    it_behaves_like 'code with offense',
                    'foo = (bar = baz = find_baz) ? a : b'
  end

  context 'when configured to enforce parentheses inclusion' do
    let(:rule_config) { { 'EnforcedStyle' => 'require_parentheses' } }

    let(:message) { 'Use parentheses for ternary conditions.' }

    context 'with a simple condition' do
      it_behaves_like 'code with offense',
                      'foo = bar? ? a : b',
                      'foo = (bar?) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = yield ? a : b',
                      'foo = (yield) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar[:baz] ? a : b',
                      'foo = (bar[:baz]) ? a : b'
    end

    context 'with a complex condition' do
      it_behaves_like 'code with offense',
                      'foo = 1 + 1 == 2 ? a : b',
                      'foo = (1 + 1 == 2) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar && baz ? a : b',
                      'foo = (bar && baz) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = foo1 == foo2 ? a : b',
                      'foo = (foo1 == foo2) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar.baz? ? a : b',
                      'foo = (bar.baz?) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar && (baz || bar) ? a : b',
                      'foo = (bar && (baz || bar)) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar or baz ? a : b',
                      'foo = bar or (baz) ? a : b'

      it_behaves_like 'code with offense',
                      'not bar ? a : b',
                      'not (bar) ? a : b'
    end

    context 'with an assignment condition' do
      it_behaves_like 'code with offense',
                      'foo = bar = baz ? a : b',
                      'foo = bar = (baz) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar = baz = find_baz ? a : b',
                      'foo = bar = baz = (find_baz) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar = baz == 1 ? a : b',
                      'foo = bar = (baz == 1) ? a : b'

      it_behaves_like 'code without offense',
                      'foo = (bar = baz = find_baz) ? a : b'
    end
  end

  context 'when configured to enforce parentheses omission' do
    let(:rule_config) { { 'EnforcedStyle' => 'require_no_parentheses' } }

    let(:message) { 'Omit parentheses for ternary conditions.' }

    context 'with a simple condition' do
      it_behaves_like 'code with offense',
                      'foo = (bar?) ? a : b',
                      'foo = bar? ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (yield) ? a : b',
                      'foo = yield ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (bar[:baz]) ? a : b',
                      'foo = bar[:baz] ? a : b'

      it_behaves_like 'code with offense', <<~RUBY, <<~CORRECTION
        (foo ||
          bar) ? a : b
      RUBY
        foo ||
          bar ? a : b
      CORRECTION

      it_behaves_like 'code without offense', <<~RUBY
        (
          foo || bar
        ) ? a : b
      RUBY
    end

    context 'with a complex condition' do
      it_behaves_like 'code with offense',
                      'foo = (1 + 1 == 2) ? a : b',
                      'foo = 1 + 1 == 2 ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (foo1 == foo2) ? a : b',
                      'foo = foo1 == foo2 ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (bar && baz) ? a : b',
                      'foo = bar && baz ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (bar.baz?) ? a : b',
                      'foo = bar.baz? ? a : b'

      it_behaves_like 'code without offense',
                      'foo = bar && (baz || bar) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (foo or bar) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (not bar) ? a : b'
    end

    context 'with an assignment condition' do
      it_behaves_like 'code without offense',
                      'foo = (bar = find_bar) ? a : b'

      it_behaves_like 'code without offense',
                      'foo = bar = (baz = find_baz) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar = (baz == 1) ? a : b',
                      'foo = bar = baz == 1 ? a : b'

      it_behaves_like 'code without offense',
                      'foo = (bar = baz = find_baz) ? a : b'

      it_behaves_like 'safe assignment disabled', 'require_no_parentheses'
    end

    context 'with an unparenthesized method call condition' do
      it_behaves_like 'code with offense',
                      'foo = (defined? bar) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (baz? bar) ? a : b'

      context 'when calling method on a receiver' do
        it_behaves_like 'code with offense',
                        'foo = (baz.foo? bar) ? a : b'
      end

      context 'when calling method on a literal receiver' do
        it_behaves_like 'code with offense',
                        'foo = ("bar".foo? bar) ? a : b'
      end

      context 'when calling method on a constant receiver' do
        it_behaves_like 'code with offense',
                        'foo = (Bar.foo? bar) ? a : b'
      end

      context 'when calling method with multiple arguments' do
        it_behaves_like 'code with offense',
                        'foo = (baz.foo? bar, baz) ? a : b'
      end
    end

    context 'with condition including a range' do
      it_behaves_like 'code without offense',
                      '(foo..bar).include?(baz) ? a : b'
    end

    context 'with no space between the parentheses and question mark' do
      it_behaves_like 'code with offense',
                      '(foo)? a : b',
                      'foo ? a : b'
    end
  end

  context 'configured for parentheses on complex and there are parens' do
    let(:rule_config) do
      { 'EnforcedStyle' => 'require_parentheses_when_complex' }
    end

    let(:message) do
      'Only use parentheses for ternary expressions with complex conditions.'
    end

    context 'with a simple condition' do
      it_behaves_like 'code with offense',
                      'foo = (bar?) ? a : b',
                      'foo = bar? ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (yield) ? a : b',
                      'foo = yield ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (bar[:baz]) ? a : b',
                      'foo = bar[:baz] ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar or (baz) ? a : b',
                      'foo = bar or baz ? a : b'

      it_behaves_like 'code with offense',
                      'foo = (bar&.baz) ? a : b',
                      'foo = bar&.baz ? a : b'
    end

    context 'with a complex condition' do
      it_behaves_like 'code with offense',
                      'foo = (bar.baz?) ? a : b',
                      'foo = bar.baz? ? a : b'

      it_behaves_like 'code without offense',
                      'foo = (baz or bar) ? a : b'

      it_behaves_like 'code without offense',
                      'foo = (bar && (baz || bar)) ? a : b'
    end

    context 'with an assignment condition' do
      it_behaves_like 'code without offense',
                      'foo = (bar = find_bar) ? a : b'

      it_behaves_like 'code without offense',
                      'foo = baz = (bar = find_bar) ? a : b'

      it_behaves_like 'code without offense',
                      'foo = bar = (bar == 1) ? a : b'

      it_behaves_like 'code without offense',
                      'foo = (bar = baz = find_bar) ? a : b'

      it_behaves_like 'safe assignment disabled',
                      'require_parentheses_when_complex'
    end

    context 'with method call condition' do
      it_behaves_like 'code with offense',
                      'foo = (defined? bar) ? a : b'

      it_behaves_like 'code with offense',
                      '(%w(a b).include? params[:t]) ? "ab" : "c"'

      it_behaves_like 'code with offense',
                      '(%w(a b).include? params[:t], 3) ? "ab" : "c"'

      it_behaves_like 'code with offense',
                      '(%w(a b).include?(params[:t], x)) ? "ab" : "c"',
                      '%w(a b).include?(params[:t], x) ? "ab" : "c"'

      it_behaves_like 'code with offense',
                      '(%w(a b).include? "a") ? "ab" : "c"'

      it_behaves_like 'code with offense',
                      '(%w(a b).include?("a")) ? "ab" : "c"',
                      '%w(a b).include?("a") ? "ab" : "c"'

      it_behaves_like 'code with offense',
                      'foo = (baz? bar) ? a : b'

      context 'when calling method on a receiver' do
        it_behaves_like 'code with offense',
                        'foo = (baz.foo? bar) ? a : b'
      end
    end

    context 'with condition including a range' do
      it_behaves_like 'code without offense',
                      '(foo..bar).include?(baz) ? a : b'
    end
  end

  context 'configured for parentheses on complex and there are no parens' do
    let(:rule_config) do
      { 'EnforcedStyle' => 'require_parentheses_when_complex' }
    end

    let(:message) do
      'Use parentheses for ternary expressions with complex conditions.'
    end

    context 'with complex condition' do
      it_behaves_like 'code with offense',
                      'foo = 1 + 1 == 2 ? a : b',
                      'foo = (1 + 1 == 2) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar && baz ? a : b',
                      'foo = (bar && baz) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar && baz || bar ? a : b',
                      'foo = (bar && baz || bar) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar && (baz != bar) ? a : b',
                      'foo = (bar && (baz != bar)) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = 1 < (bar.baz?) ? a : b',
                      'foo = (1 < (bar.baz?)) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = 1 <= (bar ** baz) ? a : b',
                      'foo = (1 <= (bar ** baz)) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = 1 >= bar * baz ? a : b',
                      'foo = (1 >= bar * baz) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar + baz ? a : b',
                      'foo = (bar + baz) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar - baz ? a : b',
                      'foo = (bar - baz) ? a : b'

      it_behaves_like 'code with offense',
                      'foo = bar < baz ? a : b',
                      'foo = (bar < baz) ? a : b'
    end

    context 'with an assignment condition' do
      it_behaves_like 'code with offense',
                      'foo = bar = baz == 1 ? a : b',
                      'foo = bar = (baz == 1) ? a : b'

      it_behaves_like 'code without offense',
                      'foo = (bar = baz == 1) ? a : b'
    end
  end

  context 'when `RedundantParenthesis` would cause an infinite loop' do
    let(:redundant_parens_enabled) { true }

    context 'when `EnforcedStyle: require_parentheses`' do
      let(:rule_config) do
        { 'EnforcedStyle' => 'require_parentheses' }
      end

      it_behaves_like 'code without offense', 'foo = bar? ? a : b'
    end

    context 'when `EnforcedStyle: require_parentheses_when_complex`' do
      let(:rule_config) do
        { 'EnforcedStyle' => 'require_parentheses_when_complex' }
      end

      it_behaves_like 'code without offense', '!condition.nil? ? foo : bar'
    end
  end
end
