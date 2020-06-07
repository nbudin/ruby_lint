# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Layout::EmptyLinesAroundArguments, :config do
  context 'when extra lines' do
    it 'registers offense for empty line before arg' do
      inspect_source(<<~RUBY)
        foo(

          bar
        )
      RUBY
      expect(cop.messages)
        .to eq(['Empty line detected around arguments.'])
    end

    it 'registers offense for empty line after arg' do
      inspect_source(<<~RUBY)
        bar(
          [baz, qux]

        )
      RUBY
      expect(cop.messages)
        .to eq(['Empty line detected around arguments.'])
    end

    it 'registers offense for empty line between args' do
      inspect_source(<<~RUBY)
        foo.do_something(
          baz,

          qux: 0
        )
      RUBY
      expect(cop.messages)
        .to eq(['Empty line detected around arguments.'])
    end

    it 'registers offenses when multiple empty lines are detected' do
      inspect_source(<<~RUBY)
        foo(
          baz,

          qux,

          biz,

        )
      RUBY
      expect(rule.offenses.size).to eq 3
      expect(cop.messages.uniq)
        .to eq(['Empty line detected around arguments.'])
    end

    it 'registers offense when args start on definition line' do
      inspect_source(<<~RUBY)
        foo(biz,

            baz: 0)
      RUBY
      expect(cop.messages)
        .to eq(['Empty line detected around arguments.'])
    end

    it 'registers offense when empty line between normal arg & block arg' do
      inspect_source(<<~RUBY)
        Foo.prepend(
          a,

          Module.new do
            def something; end

            def anything; end
          end
        )
      RUBY
      expect(rule.offenses.size).to eq 1
      expect(cop.messages)
        .to eq(['Empty line detected around arguments.'])
    end

    it 'registers offense on correct line for single offense example' do
      inspect_source(<<~RUBY)
        class Foo

          include Bar

          def baz(qux)
            fizz(
              qux,

              10
            )
          end
        end
      RUBY
      expect(rule.offenses.size).to eq 1
      expect(rule.offenses.first.location.line).to eq 8
      expect(cop.messages.uniq)
        .to eq(['Empty line detected around arguments.'])
    end

    it 'registers offense on correct lines for multi-offense example' do
      inspect_source(<<~RUBY)
        something(1, 5)
        something_else

        foo(biz,

            qux)

        quux.map do

        end.another.thing(

          [baz]
        )
      RUBY
      expect(rule.offenses.size).to eq 2
      expect(rule.offenses[0].location.line).to eq 5
      expect(rule.offenses[1].location.line).to eq 11
      expect(cop.messages.uniq)
        .to eq(['Empty line detected around arguments.'])
    end

    context 'when using safe navigation operator' do
      it 'registers offense for empty line before arg' do
        inspect_source(<<~RUBY)
          receiver&.foo(

            bar
          )
        RUBY
        expect(cop.messages)
          .to eq(['Empty line detected around arguments.'])
      end
    end

    it 'autocorrects empty line detected at top' do
      corrected = autocorrect_source(<<~RUBY)
        foo(

          bar
        )
      RUBY

      expect(corrected).to eq(<<~RUBY)
        foo(
          bar
        )
      RUBY
    end

    it 'autocorrects empty line detected at bottom' do
      corrected = autocorrect_source(<<~RUBY)
        foo(
          baz: 1

        )
      RUBY

      expect(corrected).to eq(<<~RUBY)
        foo(
          baz: 1
        )
      RUBY
    end

    it 'autocorrects empty line detected in the middle' do
      corrected = autocorrect_source(<<~RUBY)
        do_something(
          [baz],

          qux: 0
        )
      RUBY

      expect(corrected).to eq(<<~RUBY)
        do_something(
          [baz],
          qux: 0
        )
      RUBY
    end

    it 'autocorrects multiple empty lines' do
      corrected = autocorrect_source(<<~RUBY)
        do_stuff(
          baz,

          qux,

          bar: 0,
        )
      RUBY

      expect(corrected).to eq(<<~RUBY)
        do_stuff(
          baz,
          qux,
          bar: 0,
        )
      RUBY
    end

    it 'autocorrects args that start on definition line' do
      corrected = autocorrect_source(<<~RUBY)
        bar(qux,

            78)
      RUBY

      expect(corrected).to eq(<<~RUBY)
        bar(qux,
            78)
      RUBY
    end
  end

  context 'when no extra lines' do
    it 'accpets one line methods' do
      expect_no_offenses(<<~RUBY)
        foo(bar)
      RUBY
    end

    it 'accepts multiple listed mixed args' do
      expect_no_offenses(<<~RUBY)
        foo(
          bar,
          [],
          baz = nil,
          qux: 2
        )
      RUBY
    end

    it 'accepts listed args starting on definition line' do
      expect_no_offenses(<<~RUBY)
        foo(bar,
            [],
            qux: 2)
      RUBY
    end

    it 'accepts block argument with empty line' do
      expect_no_offenses(<<~RUBY)
        Foo.prepend(Module.new do
          def something; end

          def anything; end
        end)
      RUBY
    end

    it 'accepts method with argument that trails off block' do
      expect_no_offenses(<<~RUBY)
        fred.map do
          <<-EOT
            bar

            foo
          EOT
        end.join("\n")
      RUBY
    end

    it 'accepts method with no arguments that trails off block' do
      expect_no_offenses(<<~RUBY)
        foo.baz do

          bar
        end.compact
      RUBY
    end

    it 'accepts method with argument that trails off heredoc' do
      expect_no_offenses(<<~RUBY)
        bar(<<-DOCS)
          foo

        DOCS
          .call!(true)
      RUBY
    end

    context 'with one argument' do
      it 'ignores empty lines inside of method arguments' do
        expect_no_offenses(<<~RUBY)
          private(def bar

            baz
          end)
        RUBY
      end
    end

    context 'with multiple arguments' do
      it 'ignores empty lines inside of method arguments' do
        expect_no_offenses(<<~RUBY)
          foo(:bar, [1,

                     2]
          )
        RUBY
      end
    end
  end
end
