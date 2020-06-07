# frozen_string_literal: true

RSpec.describe RuboCop::Rule::AlignmentCorrector, :config do
  let(:cop_class) { RuboCop::Rule::Test::AlignmentDirective }

  describe '#correct' do
    context 'simple indentation' do
      context 'with a positive column delta' do
        it 'indents' do
          expect(autocorrect_source(<<~INPUT)).to eq(<<~OUTPUT)
            # >> 2
              42
          INPUT
            # >> 2
                42
          OUTPUT
        end
      end

      context 'with a negative column delta' do
        it 'outdents' do
          expect(autocorrect_source(<<~INPUT)).to eq(<<~OUTPUT)
            # << 3
                42
          INPUT
            # << 3
             42
          OUTPUT
        end
      end
    end

    shared_examples 'heredoc indenter' do |start_heredoc, column_delta|
      let(:indentation) { ' ' * column_delta }
      let(:end_heredoc) { /\w+/.match(start_heredoc)[0] }

      it 'does not change indentation of here doc bodies and end markers' do
        expect(autocorrect_source(<<~INPUT)).to eq(<<~OUTPUT)
          # >> #{column_delta}
          begin
            #{start_heredoc}
          a
          b
          #{end_heredoc}
          end
        INPUT
          # >> #{column_delta}
          #{indentation}begin
          #{indentation}  #{start_heredoc}
          a
          b
          #{end_heredoc}
          #{indentation}end
        OUTPUT
      end
    end

    context 'with large column deltas' do
      context 'with plain heredoc (<<)' do
        it_behaves_like 'heredoc indenter', '<<DOC', 20
      end

      context 'with heredoc in backticks (<<``)' do
        it_behaves_like 'heredoc indenter', '<<`DOC`', 20
      end
    end

    context 'with single-line here docs' do
      it 'does not indent body and end marker' do
        indentation = '  '
        expect(autocorrect_source(<<~INPUT)).to eq(<<~OUTPUT)
          # >> 2
          begin
            <<DOC
          single line
          DOC
          end
        INPUT
          # >> 2
          #{indentation}begin
          #{indentation}  <<DOC
          single line
          DOC
          #{indentation}end
        OUTPUT
      end
    end

    context 'within string literals' do
      it 'does not insert whitespace' do
        expect(autocorrect_source(<<~INPUT)).to eq(<<~OUTPUT)
          # >> 2
          begin
            dstr =
          'a
          b
          c'
            xstr =
          `a
          b
          c`
          end
        INPUT
          # >> 2
            begin
              dstr =
            'a
          b
          c'
              xstr =
            `a
          b
          c`
            end
        OUTPUT
      end
    end
  end
end
