# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Lint::RaiseException, :config do
  let(:rule_config) { { 'AllowedImplicitNamespaces' => ['Gem'] } }

  it 'registers an offense for `raise` with `::Exception`' do
    expect_offense(<<~RUBY)
      raise ::Exception
      ^^^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'registers an offense for `raise` with `::Exception.new`' do
    expect_offense(<<~RUBY)
      raise ::Exception.new 'Error with exception'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'registers an offense for `raise` with `::Exception` and message' do
    expect_offense(<<~RUBY)
      raise ::Exception, 'Error with exception'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'registers an offense for `raise` with `Exception`' do
    expect_offense(<<~RUBY)
      raise Exception
      ^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'registers an offense for `raise` with `Exception` and message' do
    expect_offense(<<~RUBY)
      raise Exception, 'Error with exception'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'registers an offense for `raise` with `Exception.new` and message' do
    expect_offense(<<~RUBY)
      raise Exception.new 'Error with exception'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'registers an offense for `raise` with `Exception.new(args*)` ' do
    expect_offense(<<~RUBY)
      raise Exception.new('arg1', 'arg2')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'registers an offense for `fail` with `Exception`' do
    expect_offense(<<~RUBY)
      fail Exception
      ^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'registers an offense for `fail` with `Exception` and message' do
    expect_offense(<<~RUBY)
      fail Exception, 'Error with exception'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'registers an offense for `fail` with `Exception.new` and message' do
    expect_offense(<<~RUBY)
      fail Exception.new 'Error with exception'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
    RUBY
  end

  it 'does not register an offense for `raise` without arguments' do
    expect_no_offenses('raise')
  end

  it 'does not register an offense for `fail` without arguments' do
    expect_no_offenses('fail')
  end

  it 'does not register an offense when raising Exception with explicit ' \
     'namespace' do
    expect_no_offenses(<<~RUBY)
      raise Foo::Exception
    RUBY
  end

  context 'when under namespace' do
    it 'does not register an offense when Exception without cbase specified' do
      expect_no_offenses(<<~RUBY)
        module Gem
          def self.foo
            raise Exception
          end
        end
      RUBY
    end

    it 'does not register an offense when Exception with cbase specified' do
      expect_offense(<<~RUBY)
        module Gem
          def self.foo
            raise ::Exception
            ^^^^^^^^^^^^^^^^^ Use `StandardError` over `Exception`.
          end
        end
      RUBY
    end
  end
end
