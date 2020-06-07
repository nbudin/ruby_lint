# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Lint::SuppressedException, :config do
  context 'with AllowComments set to false' do
    let(:rule_config) { { 'AllowComments' => false } }

    it 'registers an offense for empty rescue block' do
      expect_offense(<<~RUBY)
        begin
          something
        rescue
        ^^^^^^ Do not suppress exceptions.
          #do nothing
        end
      RUBY
    end

    it 'does not register an offense for rescue with body' do
      expect_no_offenses(<<~RUBY)
        begin
          something
          return
        rescue
          file.close
        end
      RUBY
    end

    context 'when empty rescue for `def`' do
      it 'registers an offense for empty rescue without comment' do
        expect_offense(<<~RUBY)
          def foo
            do_something
          rescue
          ^^^^^^ Do not suppress exceptions.
          end
        RUBY
      end

      it 'registers an offense for empty rescue with comment' do
        expect_offense(<<~RUBY)
          def foo
            do_something
          rescue
          ^^^^^^ Do not suppress exceptions.
            # do nothing
          end
        RUBY
      end
    end

    context 'when empty rescue for defs' do
      it 'registers an offense for empty rescue without comment' do
        expect_offense(<<~RUBY)
          def self.foo
            do_something
          rescue
          ^^^^^^ Do not suppress exceptions.
          end
        RUBY
      end

      it 'registers an offense for empty rescue with comment' do
        expect_offense(<<~RUBY)
          def self.foo
            do_something
          rescue
          ^^^^^^ Do not suppress exceptions.
            # do nothing
          end
        RUBY
      end
    end

    context 'Ruby 2.5 or higher', :ruby25 do
      context 'when empty rescue for `do` block' do
        it 'registers an offense for empty rescue without comment' do
          expect_offense(<<~RUBY)
            foo do
              do_something
            rescue
            ^^^^^^ Do not suppress exceptions.
            end
          RUBY
        end

        it 'registers an offense for empty rescue with comment' do
          expect_offense(<<~RUBY)
            foo do
            rescue
            ^^^^^^ Do not suppress exceptions.
              # do nothing
            end
          RUBY
        end
      end
    end
  end

  context 'with AllowComments set to true' do
    let(:rule_config) { { 'AllowComments' => true } }

    it 'does not register an offense for empty rescue with comment' do
      expect_no_offenses(<<~RUBY)
        begin
          something
          return
        rescue
          # do nothing
        end
      RUBY
    end

    context 'when empty rescue for `def`' do
      it 'registers an offense for empty rescue without comment' do
        expect_offense(<<~RUBY)
          def foo
            do_something
          rescue
          ^^^^^^ Do not suppress exceptions.
          end
        RUBY
      end

      it 'does not register an offense for empty rescue with comment' do
        expect_no_offenses(<<~RUBY)
          def foo
            do_something
          rescue
            # do nothing
          end
        RUBY
      end
    end

    context 'when empty rescue for `defs`' do
      it 'registers an offense for empty rescue without comment' do
        expect_offense(<<~RUBY)
          def self.foo
            do_something
          rescue
          ^^^^^^ Do not suppress exceptions.
          end
        RUBY
      end

      it 'does not register an offense for empty rescue with comment' do
        expect_no_offenses(<<~RUBY)
          def self.foo
            do_something
          rescue
            # do nothing
          end
        RUBY
      end
    end

    context 'Ruby 2.5 or higher', :ruby25 do
      context 'when empty rescue for `do` block' do
        it 'registers an offense for empty rescue without comment' do
          expect_offense(<<~RUBY)
            foo do
              do_something
            rescue
            ^^^^^^ Do not suppress exceptions.
            end
          RUBY
        end

        it 'does not register an offense for empty rescue with comment' do
          expect_no_offenses(<<~RUBY)
            foo do
            rescue
              # do nothing
            end
          RUBY
        end
      end
    end

    it 'registers an offense for empty rescue on single line with a comment after it' do
      expect_offense(<<~RUBY)
        RSpec.describe Dummy do
          it 'dummy spec' do
            # This rescue is here to ensure the test does not fail because of the `raise`
            expect { begin subject; rescue ActiveRecord::Rollback; end }.not_to(change(Post, :count))
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not suppress exceptions.
            # Done
          end
        end
      RUBY
    end
  end
end
