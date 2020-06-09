# frozen_string_literal: true

RSpec.describe RuboCop::Formatter::DisabledConfigFormatter, :isolated_environment do
  include FileHelper

  subject(:formatter) { described_class.new(output) }

  let(:output) do
    io = StringIO.new

    def io.path
      '.rubocop_todo.yml'
    end

    io
  end

  let(:offenses) do
    [RuboCop::Rule::Offense.new(:convention, location, 'message', 'Rule1'),
     RuboCop::Rule::Offense.new(:convention, location, 'message', 'Rule2')]
  end

  let(:location) { OpenStruct.new(line: 1, column: 5) }

  let(:heading) do
    format(
      described_class::HEADING,
      command: expected_heading_command,
      timestamp: expected_heading_timestamp
    )
  end

  let(:expected_heading_command) do
    'rubocop --auto-gen-config'
  end

  let(:expected_heading_timestamp) do
    "on #{Time.now} "
  end

  around do |example|
    original_stdout = $stdout
    original_stderr = $stderr

    $stdout = StringIO.new
    $stderr = StringIO.new

    example.run

    $stdout = original_stdout
    $stderr = original_stderr
  end

  before do
    # Avoid intermittent failure when another test set ConfigLoader options
    RuboCop::ConfigLoader.clear_options

    allow(Time).to receive(:now).and_return(Time.now)
  end

  context 'when any offenses are detected' do
    before do
      formatter.started(['test_a.rb', 'test_b.rb'])
      formatter.file_started('test_a.rb', {})
      formatter.file_finished('test_a.rb', offenses)
      formatter.file_started('test_b.rb', {})
      formatter.file_finished('test_b.rb', [offenses.first])
      formatter.finished(['test_a.rb', 'test_b.rb'])
    end

    let(:expected_rubocop_todo) do
      [heading,
       '# Offense count: 2',
       'Rule1:',
       '  Exclude:',
       "    - 'test_a.rb'",
       "    - 'test_b.rb'",
       '',
       '# Offense count: 1',
       'Rule2:',
       '  Exclude:',
       "    - 'test_a.rb'",
       ''].join("\n")
    end

    it 'displays YAML configuration disabling all rules with offenses' do
      expect(output.string).to eq(expected_rubocop_todo)
      expect($stdout.string).to eq("Created .rubocop_todo.yml.\n")
    end
  end

  context "when there's .rubocop.yml" do
    before do
      create_file('.rubocop.yml', <<~YAML)
        Rule1:
          Exclude:
            - Gemfile
        Rule2:
          Exclude:
            - "**/*.blah"
            - !ruby/regexp /.*/bar/*/foo\.rb$/
      YAML

      formatter.started(['test_a.rb', 'test_b.rb'])
      formatter.file_started('test_a.rb', {})
      formatter.file_finished('test_a.rb', offenses)
      formatter.file_started('test_b.rb', {})
      formatter.file_finished('test_b.rb', [offenses.first])

      # Rule1 and Rule2 are unknown rules and would raise an validation error
      allow(RuboCop::Rule::Rule.registry).to receive(:contains_rule_matching?)
        .and_return(true)
      formatter.finished(['test_a.rb', 'test_b.rb'])
    end

    let(:expected_rubocop_todo) do
      [heading,
       '# Offense count: 2',
       'Rule1:',
       '  Exclude:',
       "    - 'Gemfile'",
       "    - 'test_a.rb'",
       "    - 'test_b.rb'",
       '',
       '# Offense count: 1',
       'Rule2:',
       '  Exclude:',
       "    - '**/*.blah'",
       "    - !ruby/regexp /.*/bar/*/foo\.rb$/",
       "    - 'test_a.rb'",
       ''].join("\n")
    end

    it 'merges in excludes from .rubocop.yml' do
      expect(output.string).to eq(expected_rubocop_todo)
    end
  end

  context 'when exclude_limit option is omitted' do
    before do
      formatter.started(filenames)

      filenames.each do |filename|
        formatter.file_started(filename, {})

        if filename == filenames.last
          formatter.file_finished(filename, [offenses.first])
        else
          formatter.file_finished(filename, offenses)
        end
      end

      formatter.finished(filenames)
    end

    let(:filenames) do
      Array.new(16) { |index| format('test_%02d.rb', index + 1) }
    end

    let(:expected_rubocop_todo) do
      [heading,
       '# Offense count: 16',
       'Rule1:',
       '  Enabled: false',
       '',
       '# Offense count: 15',
       'Rule2:',
       '  Exclude:',
       "    - 'test_01.rb'",
       "    - 'test_02.rb'",
       "    - 'test_03.rb'",
       "    - 'test_04.rb'",
       "    - 'test_05.rb'",
       "    - 'test_06.rb'",
       "    - 'test_07.rb'",
       "    - 'test_08.rb'",
       "    - 'test_09.rb'",
       "    - 'test_10.rb'",
       "    - 'test_11.rb'",
       "    - 'test_12.rb'",
       "    - 'test_13.rb'",
       "    - 'test_14.rb'",
       "    - 'test_15.rb'",
       ''].join("\n")
    end

    it 'disables the rule with 15 offending files' do
      expect(output.string).to eq(expected_rubocop_todo)
    end
  end

  context 'when exclude_limit option is passed' do
    before do
      formatter.started(filenames)

      filenames.each do |filename|
        formatter.file_started(filename, {})

        if filename == filenames.last
          formatter.file_finished(filename, [offenses.first])
        else
          formatter.file_finished(filename, offenses)
        end
      end

      formatter.finished(filenames)
    end

    let(:formatter) { described_class.new(output, exclude_limit: 5) }

    let(:filenames) do
      Array.new(6) { |index| format('test_%02d.rb', index + 1) }
    end

    let(:expected_heading_command) do
      'rubocop --auto-gen-config --exclude-limit 5'
    end

    let(:expected_rubocop_todo) do
      [heading,
       '# Offense count: 6',
       'Rule1:',
       '  Enabled: false',
       '',
       '# Offense count: 5',
       'Rule2:',
       '  Exclude:',
       "    - 'test_01.rb'",
       "    - 'test_02.rb'",
       "    - 'test_03.rb'",
       "    - 'test_04.rb'",
       "    - 'test_05.rb'",
       ''].join("\n")
    end

    it 'respects the file exclusion list limit' do
      expect(output.string).to eq(expected_rubocop_todo)
    end
  end

  context 'when no files are inspected' do
    before do
      formatter.started([])
      formatter.finished([])
    end

    it 'creates a .rubocop_todo.yml even in such case' do
      expect(output.string).to eq(heading)
    end
  end

  context 'with auto-correct supported rule' do
    before do
      stub_const('Test::Rule3',
                 Class.new(::RuboCop::Rule::Rule) do
                   def autocorrect
                     # Dummy method to respond to #support_autocorrect?
                   end
                 end)

      formatter.started(['test_auto_correct.rb'])
      formatter.file_started('test_auto_correct.rb', {})
      formatter.file_finished('test_auto_correct.rb', offenses)
      formatter.finished(['test_auto_correct.rb'])
    end

    let(:expected_rubocop_todo) do
      [heading,
       '# Offense count: 1',
       '# Rule supports --auto-correct.',
       'Test/Rule3:',
       '  Exclude:',
       "    - 'test_auto_correct.rb'",
       ''].join("\n")
    end

    let(:offenses) do
      [
        RuboCop::Rule::Offense.new(
          :convention,
          location,
          'message',
          'Test/Rule3'
        )
      ]
    end

    it 'adds a comment about --auto-correct option' do
      expect(output.string).to eq(expected_rubocop_todo)
    end
  end
end
