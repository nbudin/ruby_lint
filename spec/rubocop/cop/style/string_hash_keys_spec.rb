# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::StringHashKeys do
  subject(:rule) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  it 'registers an offense when using strings as keys' do
    expect_offense(<<~RUBY)
      { 'one' => 1 }
        ^^^^^ Prefer symbols instead of strings as hash keys.
    RUBY
  end

  it 'registers an offense when using strings as keys mixed with other keys' do
    expect_offense(<<~RUBY)
      { 'one' => 1, two: 2, 3 => 3 }
        ^^^^^ Prefer symbols instead of strings as hash keys.
    RUBY
  end

  it 'autocorrects strings as keys into symbols' do
    new_source = autocorrect_source("{ 'one' => 1 }")
    expect(new_source).to eq '{ :one => 1 }'
  end

  it 'autocorrects strings as keys mixed with other keys into symbols' do
    new_source = autocorrect_source("{ 'one' => 1, two: 2, 3 => 3 }")
    expect(new_source).to eq '{ :one => 1, two: 2, 3 => 3 }'
  end

  it 'autocorrects strings as keys into symbols with the correct syntax' do
    new_source = autocorrect_source("{ 'one two :' => 1 }")
    expect(new_source).to eq '{ :"one two :" => 1 }'
  end

  it 'does not register an offense when not using strings as keys' do
    expect_no_offenses(<<~RUBY)
      { one: 1 }
    RUBY
  end

  it 'does not register an offense when string key is used in IO.popen' do
    expect_no_offenses(<<~RUBY)
      IO.popen({"RUBYOPT" => '-w'}, 'ruby', 'foo.rb')
    RUBY
  end

  it 'does not register an offense when string key is used in Open3.capture3' do
    expect_no_offenses(<<~RUBY)
      Open3.capture3({"RUBYOPT" => '-w'}, 'ruby', 'foo.rb')
    RUBY
  end

  it 'does not register an offense when string key is used in Open3.pipeline' do
    expect_no_offenses(<<~RUBY)
      Open3.pipeline([{"RUBYOPT" => '-w'}, 'ruby', 'foo.rb'], ['wc', '-l'])
    RUBY
  end

  it 'does not register an offense when string key is used in gsub' do
    expect_no_offenses(<<~RUBY)
      "The sky is green.".gsub(/green/, "green" => "blue")
    RUBY
  end

  it 'does not register an offense when string key is used in gsub!' do
    expect_no_offenses(<<~RUBY)
      "The sky is green.".gsub!(/green/, "green" => "blue")
    RUBY
  end
end
