# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Gemspec::RequiredRubyVersion, :config do
  context 'target ruby version > 2.7', :ruby27 do
    it 'registers an offense when `required_ruby_version` is lower than ' \
       '`TargetRubyVersion`' do
      expect_offense(<<~RUBY, '/path/to/foo.gemspec')
        Gem::Specification.new do |spec|
          spec.required_ruby_version = '>= 2.6.0'
                                       ^^^^^^^^^^ `required_ruby_version` (2.6, declared in foo.gemspec) and `TargetRubyVersion` (2.7, which may be specified in .rubocop.yml) should be equal.
        end
      RUBY
    end

    describe 'false negatives' do
      it 'does not register an offense when `required_ruby_version` ' \
         'is assigned as a variable (string literal)' do
        expect_no_offenses(<<~RUBY)
          Gem::Specification.new do |spec|
            version = '>= 2.6.0'
            spec.required_ruby_version = version
          end
        RUBY
      end

      it 'does not register an offense when `required_ruby_version` ' \
         'is assigned as a variable (an array of string literal)' do
        expect_no_offenses(<<~RUBY)
          Gem::Specification.new do |spec|
            lowest_version = '>= 2.6.0'
            highest_version = '< 2.8.0'
            spec.required_ruby_version = [lowest_version, highest_version]
          end
        RUBY
      end
    end
  end

  context 'target ruby version > 2.5', :ruby25 do
    it 'registers an offense when `required_ruby_version` is higher than ' \
       '`TargetRubyVersion`' do
      expect_offense(<<~RUBY, '/path/to/bar.gemspec')
        Gem::Specification.new do |spec|
          spec.required_ruby_version = '>= 2.6.0'
                                       ^^^^^^^^^^ `required_ruby_version` (2.6, declared in bar.gemspec) and `TargetRubyVersion` (2.5, which may be specified in .rubocop.yml) should be equal.
        end
      RUBY
    end
  end

  context 'target ruby version > 2.6', :ruby26 do
    it 'does not register an offense when `required_ruby_version` equals ' \
       '`TargetRubyVersion`' do
      expect_no_offenses(<<~RUBY)
        Gem::Specification.new do |spec|
          spec.required_ruby_version = '>= 2.6.0'
        end
      RUBY
    end

    it 'does not register an offense when `required_ruby_version` ' \
       '(omit patch version) equals `TargetRubyVersion`' do
      expect_no_offenses(<<~RUBY)
        Gem::Specification.new do |spec|
          spec.required_ruby_version = '>= 2.6'
        end
      RUBY
    end

    it 'does not register an offense when lowest version of ' \
       '`required_ruby_version` equals `TargetRubyVersion`' do
      expect_no_offenses(<<~RUBY)
        Gem::Specification.new do |spec|
          spec.required_ruby_version = ['>= 2.6.0', '< 2.8.0']
        end
      RUBY
    end
  end
end
