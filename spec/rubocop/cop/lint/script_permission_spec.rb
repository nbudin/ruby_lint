# frozen_string_literal: true

# rubocop:disable Style/NumericLiteralPrefix
RSpec.describe RuboCop::Rule::Lint::ScriptPermission do
  subject(:rule) { described_class.new(config, options) }

  let(:config) { RuboCop::Config.new }
  let(:options) { nil }

  let(:file) { Tempfile.new('') }
  let(:filename) { file.path.split('/').last }
  let(:source) { '#!/usr/bin/ruby' }

  after do
    file.close
    file.unlink
  end

  context 'with file permission 0644' do
    before do
      File.write(file.path, source)
      FileUtils.chmod(0644, file.path)
    end

    if RuboCop::Platform.windows?
      context 'Windows' do
        it 'allows any file permissions' do
          expect_no_offenses(<<~RUBY, file)
            #!/usr/bin/ruby
          RUBY
        end
      end
    else
      it 'registers an offense for script permission' do
        expect_offense(<<~RUBY, file)
          #!/usr/bin/ruby
          ^^^^^^^^^^^^^^^ Script file #{filename} doesn't have execute permission.
        RUBY
      end
    end
  end

  context 'with file permission 0755' do
    before do
      FileUtils.chmod(0755, file.path)
    end

    it 'accepts with shebang line' do
      File.write(file.path, source)

      expect_no_offenses(file.read, file)
    end

    it 'accepts without shebang line' do
      File.write(file.path, 'puts "hello"')

      expect_no_offenses(file.read, file)
    end

    it 'accepts with blank' do
      File.write(file.path, '')

      expect_no_offenses(file.read, file)
    end
  end

  context 'with stdin' do
    let(:options) { { stdin: '' } }

    it 'skips investigation' do
      expect_no_offenses(source)
    end
  end

  unless RuboCop::Platform.windows?
    context 'auto-correct' do
      it 'adds execute permissions to the file' do
        File.write(file.path, source)

        autocorrect_source(file.read, file)

        expect(file.stat.executable?).to be_truthy
      end
    end
  end
end
# rubocop:enable Style/NumericLiteralPrefix
