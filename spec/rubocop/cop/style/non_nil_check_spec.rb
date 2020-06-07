# frozen_string_literal: true

RSpec.describe Rubocop::Rule::Style::NonNilCheck, :config do
  context 'when not allowing semantic changes' do
    let(:cop_config) do
      {
        'IncludeSemanticChanges' => false
      }
    end

    it 'registers an offense for != nil' do
      expect_offense(<<~RUBY)
        x != nil
          ^^ Prefer `!expression.nil?` over `expression != nil`.
      RUBY
    end

    it 'does not register an offense for != 0' do
      expect_no_offenses('x != 0')
    end

    it 'does not register an offense for !x.nil?' do
      expect_no_offenses('!x.nil?')
    end

    it 'does not register an offense for not x.nil?' do
      expect_no_offenses('not x.nil?')
    end

    it 'does not register an offense if only expression in predicate' do
      expect_no_offenses(<<~RUBY)
        def signed_in?
          !current_user.nil?
        end
      RUBY
    end

    it 'does not register an offense if only expression in class predicate' do
      expect_no_offenses(<<~RUBY)
        def Test.signed_in?
          current_user != nil
        end
      RUBY
    end

    it 'does not register an offense if last expression in predicate' do
      expect_no_offenses(<<~RUBY)
        def signed_in?
          something
          current_user != nil
        end
      RUBY
    end

    it 'does not register an offense if last expression in class predicate' do
      expect_no_offenses(<<~RUBY)
        def Test.signed_in?
          something
          current_user != nil
        end
      RUBY
    end

    it 'autocorrects by changing `!= nil` to `!x.nil?`' do
      corrected = autocorrect_source('x != nil')
      expect(corrected).to eq '!x.nil?'
    end

    it 'does not autocorrect by removing non-nil (!x.nil?) check' do
      corrected = autocorrect_source('!x.nil?')
      expect(corrected).to eq '!x.nil?'
    end

    it 'does not blow up when autocorrecting implicit receiver' do
      corrected = autocorrect_source('!nil?')
      expect(corrected).to eq '!nil?'
    end

    it 'does not report corrected when the code was not modified' do
      source = 'return nil unless (line =~ //) != nil'
      corrected = autocorrect_source(source)

      expect(corrected).to eq(source)
      expect(cop.corrections.empty?).to be(true)
    end
  end

  context 'when allowing semantic changes' do
    subject(:cop) { described_class.new(config) }

    let(:cop_config) do
      {
        'IncludeSemanticChanges' => true
      }
    end

    it 'registers an offense for `!x.nil?`' do
      expect_offense(<<~RUBY)
        !x.nil?
        ^^^^^^^ Explicit non-nil checks are usually redundant.
      RUBY
    end

    it 'registers an offense for unless x.nil?' do
      expect_offense(<<~RUBY)
        puts b unless x.nil?
                      ^^^^^^ Explicit non-nil checks are usually redundant.
      RUBY
    end

    it 'does not register an offense for `x.nil?`' do
      expect_no_offenses('x.nil?')
    end

    it 'does not register an offense for `!x`' do
      expect_no_offenses('!x')
    end

    it 'registers an offense for `not x.nil?`' do
      expect_offense(<<~RUBY)
        not x.nil?
        ^^^^^^^^^^ Explicit non-nil checks are usually redundant.
      RUBY
    end

    it 'does not blow up with ternary operators' do
      expect_no_offenses('my_var.nil? ? 1 : 0')
    end

    it 'autocorrects by changing unless x.nil? to if x' do
      corrected = autocorrect_source('puts a unless x.nil?')
      expect(corrected).to eq 'puts a if x'
    end

    it 'autocorrects by changing `x != nil` to `x`' do
      corrected = autocorrect_source('x != nil')
      expect(corrected).to eq 'x'
    end

    it 'autocorrects by changing `!x.nil?` to `x`' do
      corrected = autocorrect_source('!x.nil?')
      expect(corrected).to eq 'x'
    end

    it 'does not blow up when autocorrecting implicit receiver' do
      corrected = autocorrect_source('!nil?')
      expect(corrected).to eq 'self'
    end

    it 'corrects code that would not be modified if ' \
       'IncludeSemanticChanges were false' do
      corrected = autocorrect_source('return nil unless (line =~ //) != nil')

      expect(corrected).to eq('return nil unless (line =~ //)')
    end
  end
end
