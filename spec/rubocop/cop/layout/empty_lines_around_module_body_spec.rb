# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Layout::EmptyLinesAroundModuleBody, :config do
  let(:extra_begin) { 'Extra empty line detected at module body beginning.' }
  let(:extra_end) { 'Extra empty line detected at module body end.' }
  let(:missing_begin) { 'Empty line missing at module body beginning.' }
  let(:missing_end) { 'Empty line missing at module body end.' }
  let(:missing_def) { 'Empty line missing before first def definition' }
  let(:missing_type) { 'Empty line missing before first module definition' }

  context 'when EnforcedStyle is no_empty_lines' do
    let(:rule_config) { { 'EnforcedStyle' => 'no_empty_lines' } }

    it 'registers an offense for module body starting with a blank' do
      inspect_source(<<~RUBY)
        module SomeModule

          do_something
        end
      RUBY

      expect(cop.messages).to eq([extra_begin])
    end

    it 'registers an offense for module body ending with a blank' do
      inspect_source(<<~RUBY)
        module SomeModule
          do_something

        end
      RUBY

      expect(cop.messages).to eq([extra_end])
    end

    it 'autocorrects beginning and end' do
      new_source = autocorrect_source(<<~RUBY)
        module SomeModule

          do_something

        end
      RUBY

      expect(new_source).to eq(<<~RUBY)
        module SomeModule
          do_something
        end
      RUBY
    end
  end

  context 'when EnforcedStyle is empty_lines' do
    let(:rule_config) { { 'EnforcedStyle' => 'empty_lines' } }

    it 'registers an offense for module body not starting or ending with a ' \
       'blank' do
      inspect_source(<<~RUBY)
        module SomeModule
          do_something
        end
      RUBY

      expect(cop.messages).to eq([missing_begin, missing_end])
    end

    it 'registers an offense for module body not ending with a blank' do
      expect_offense(<<~RUBY)
        module SomeModule

          do_something
        end
        ^ Empty line missing at module body end.
      RUBY
    end

    it 'autocorrects beginning and end' do
      new_source = autocorrect_source(<<~RUBY)
        module SomeModule
          do_something
        end
      RUBY

      expect(new_source).to eq(<<~RUBY)
        module SomeModule

          do_something

        end
      RUBY
    end

    it 'accepts modules with an empty body' do
      expect_no_offenses(<<~RUBY)
        module A
        end
      RUBY
    end
  end

  context 'when EnforcedStyle is empty_lines_except_namespace' do
    let(:rule_config) { { 'EnforcedStyle' => 'empty_lines_except_namespace' } }

    context 'when only child is module' do
      it 'requires no empty lines for namespace' do
        expect_no_offenses(<<~RUBY)
          module Parent
            module Child

              do_something

            end
          end
        RUBY
      end

      it 'registers offense for namespace body starting with a blank' do
        inspect_source(<<~RUBY)
          module Parent

            module Child

              do_something

            end
          end
        RUBY

        expect(cop.messages).to eq([extra_begin])
      end

      it 'registers offense for namespace body ending with a blank' do
        inspect_source(<<~RUBY)
          module Parent
            module Child

              do_something

            end

          end
        RUBY

        expect(cop.messages).to eq([extra_end])
      end

      it 'registers offenses for namespaced module body not starting '\
          'with a blank' do
        inspect_source(<<~RUBY)
          module Parent
            module Child
              do_something

            end
          end
        RUBY

        expect(cop.messages).to eq([missing_begin])
      end

      it 'registers offenses for namespaced module body not ending '\
          'with a blank' do
        inspect_source(<<~RUBY)
          module Parent
            module Child

              do_something
            end
          end
        RUBY

        expect(cop.messages).to eq([missing_end])
      end

      it 'autocorrects beginning and end' do
        new_source = autocorrect_source(<<~RUBY)
          module Parent

            module Child
              do_something
            end

          end
        RUBY

        expect(new_source).to eq(<<~RUBY)
          module Parent
            module Child

              do_something

            end
          end
        RUBY
      end
    end

    context 'when only child is class' do
      it 'requires no empty lines for namespace' do
        expect_no_offenses(<<~RUBY)
          module Parent
            class SomeClass
              do_something
            end
          end
        RUBY
      end

      it 'registers offense for namespace body starting with a blank' do
        inspect_source(<<~RUBY)
          module Parent

            class SomeClass
              do_something
            end
          end
        RUBY

        expect(cop.messages).to eq([extra_begin])
      end

      it 'registers offense for namespace body ending with a blank' do
        inspect_source(<<~RUBY)
          module Parent
            class SomeClass
              do_something
            end

          end
        RUBY

        expect(cop.messages).to eq([extra_end])
      end
    end

    context 'when has multiple child modules' do
      it 'requires empty lines for namespace' do
        expect_no_offenses(<<~RUBY)
          module Parent

            module Mom

              do_something

            end
            module Dad

            end

          end
        RUBY
      end

      it 'registers offenses for namespace body starting '\
        'and ending without a blank' do
        inspect_source(<<~RUBY)
          module Parent
            module Mom

              do_something

            end
            module Dad

            end
          end
        RUBY

        expect(cop.messages).to eq([missing_begin, missing_end])
      end
    end
  end

  include_examples 'empty_lines_around_class_or_module_body', 'module'
end
