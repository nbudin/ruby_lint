# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::Dir, :config do
  shared_examples 'auto-correct' do |original, expected|
    it 'auto-corrects' do
      new_source = autocorrect_source(original)

      expect(new_source).to eq(expected)
    end
  end

  it 'registers an offense when using `#expand_path` and `#dirname`' do
    expect_offense(<<~RUBY)
      File.expand_path(File.dirname(__FILE__))
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `__dir__` to get an absolute path to the current file's directory.
    RUBY
  end

  it_behaves_like 'auto-correct',
                  'File.expand_path(File.dirname(__FILE__))',
                  '__dir__'

  it 'registers an offense when using `#dirname` and `#realpath`' do
    expect_offense(<<~RUBY)
      File.dirname(File.realpath(__FILE__))
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `__dir__` to get an absolute path to the current file's directory.
    RUBY
  end

  it_behaves_like 'auto-correct',
                  'File.dirname(File.realpath(__FILE__))',
                  '__dir__'
end
