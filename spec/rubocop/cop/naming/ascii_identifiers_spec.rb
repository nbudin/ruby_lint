# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Naming::AsciiIdentifiers do
  subject(:rule) { described_class.new }

  it 'registers an offense for a variable name with non-ascii chars' do
    expect_offense(<<~RUBY)
      älg = 1
      ^ Use only ascii symbols in identifiers.
    RUBY
  end

  it 'registers an offense for a variable name with mixed chars' do
    expect_offense(<<~RUBY)
      foo∂∂bar = baz
         ^^ Use only ascii symbols in identifiers.
    RUBY
  end

  it 'accepts identifiers with only ascii chars' do
    expect_no_offenses('x.empty?')
  end

  it 'does not get confused by a byte order mark' do
    expect_no_offenses(<<~RUBY)
      ﻿
      puts 'foo'
    RUBY
  end

  it 'does not get confused by an empty file' do
    expect_no_offenses('')
  end
end
