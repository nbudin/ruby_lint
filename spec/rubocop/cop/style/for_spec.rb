# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::For, :config do
  context 'when each is the enforced style' do
    let(:rule_config) { { 'EnforcedStyle' => 'each' } }

    it 'registers an offense for for' do
      expect_offense(<<~RUBY)
        def func
          for n in [1, 2, 3] do
          ^^^^^^^^^^^^^^^^^^^^^ Prefer `each` over `for`.
            puts n
          end
        end
      RUBY
    end

    it 'registers an offense for opposite + correct style' do
      expect_offense(<<~RUBY)
        def func
          for n in [1, 2, 3] do
          ^^^^^^^^^^^^^^^^^^^^^ Prefer `each` over `for`.
            puts n
          end
          [1, 2, 3].each do |n|
            puts n
          end
        end
      RUBY
    end

    context 'auto-correct' do
      it 'changes for to each' do
        new_source = autocorrect_source(<<~RUBY)
          def func
            for n in [1, 2, 3] do
              puts n
            end
          end
        RUBY

        expect(new_source).to eq(<<~RUBY)
          def func
            [1, 2, 3].each do |n|
              puts n
            end
          end
        RUBY
      end

      context 'with range' do
        let(:expected_each_with_range) do
          <<~RUBY
            def func
              (1...value).each do |n|
                puts n
              end
            end
          RUBY
        end

        it 'changes for to each' do
          new_source = autocorrect_source(<<~RUBY)
            def func
              for n in (1...value) do
                puts n
              end
            end
          RUBY

          expect(new_source).to eq(expected_each_with_range)
        end

        it 'changes for that does not have do or semicolon to each' do
          new_source = autocorrect_source(<<~RUBY)
            def func
              for n in (1...value)
                puts n
              end
            end
          RUBY

          expect(new_source).to eq(expected_each_with_range)
        end

        context 'without parentheses' do
          it 'changes for to each' do
            new_source = autocorrect_source(<<~RUBY)
              def func
                for n in 1...value do
                  puts n
                end
              end
            RUBY

            expect(new_source).to eq(expected_each_with_range)
          end

          it 'changes for that does not have do or semicolon to each' do
            new_source = autocorrect_source(<<~RUBY)
              def func
                for n in 1...value
                  puts n
                end
              end
            RUBY

            expect(new_source).to eq(expected_each_with_range)
          end
        end
      end

      it 'corrects a tuple of items' do
        new_source = autocorrect_source(<<~RUBY)
          def func
            for (a, b) in {a: 1, b: 2, c: 3} do
              puts a, b
            end
          end
        RUBY

        expect(new_source).to eq(<<~RUBY)
          def func
            {a: 1, b: 2, c: 3}.each do |(a, b)|
              puts a, b
            end
          end
        RUBY
      end

      it 'changes for that does not have do or semicolon to each' do
        new_source = autocorrect_source(<<~RUBY)
          def func
            for n in [1, 2, 3]
              puts n
            end
          end
        RUBY

        expect(new_source).to eq(<<~RUBY)
          def func
            [1, 2, 3].each do |n|
              puts n
            end
          end
        RUBY
      end
    end

    it 'accepts multiline each' do
      expect_no_offenses(<<~RUBY)
        def func
          [1, 2, 3].each do |n|
            puts n
          end
        end
      RUBY
    end

    it 'accepts :for' do
      expect_no_offenses('[:for, :ala, :bala]')
    end

    it 'accepts def for' do
      expect_no_offenses('def for; end')
    end
  end

  context 'when for is the enforced style' do
    let(:rule_config) { { 'EnforcedStyle' => 'for' } }

    it 'accepts for' do
      expect_no_offenses(<<~RUBY)
        def func
          for n in [1, 2, 3] do
            puts n
          end
        end
      RUBY
    end

    it 'registers an offense for multiline each' do
      expect_offense(<<~RUBY)
        def func
          [1, 2, 3].each do |n|
          ^^^^^^^^^^^^^^^^^^^^^ Prefer `for` over `each`.
            puts n
          end
        end
      RUBY
    end

    it 'registers an offense for each without an item' do
      expect_offense(<<~RUBY)
        def func
          [1, 2, 3].each do
          ^^^^^^^^^^^^^^^^^ Prefer `for` over `each`.
            something
          end
        end
      RUBY
    end

    it 'registers an offense for correct + opposite style' do
      expect_offense(<<~RUBY)
        def func
          for n in [1, 2, 3] do
            puts n
          end
          [1, 2, 3].each do |n|
          ^^^^^^^^^^^^^^^^^^^^^ Prefer `for` over `each`.
            puts n
          end
        end
      RUBY
    end

    context 'auto-correct' do
      it 'changes each to for' do
        new_source = autocorrect_source(<<~RUBY)
          def func
            [1, 2, 3].each do |n|
              puts n
            end
          end
        RUBY

        expect(new_source).to eq(<<~RUBY)
          def func
            for n in [1, 2, 3] do
              puts n
            end
          end
        RUBY
      end

      it 'corrects each to for and uses _ as the item' do
        new_source = autocorrect_source(<<~RUBY)
          def func
            [1, 2, 3].each do
              something
            end
          end
        RUBY

        expect(new_source).to eq(<<~RUBY)
          def func
            for _ in [1, 2, 3] do
              something
            end
          end
        RUBY
      end

      it 'corrects a tuple of items' do
        new_source = autocorrect_source(<<~RUBY)
          def func
            {a: 1, b: 2, c: 3}.each do |(a, b)|
              puts a, b
            end
          end
        RUBY

        expect(new_source).to eq(<<~RUBY)
          def func
            for (a, b) in {a: 1, b: 2, c: 3} do
              puts a, b
            end
          end
        RUBY
      end
    end

    it 'accepts single line each' do
      expect_no_offenses(<<~RUBY)
        def func
          [1, 2, 3].each { |n| puts n }
        end
      RUBY
    end

    context 'when using safe navigation operator' do
      it 'does not break' do
        expect_no_offenses(<<~RUBY)
          def func
            [1, 2, 3]&.each { |n| puts n }
          end
        RUBY
      end
    end
  end
end
