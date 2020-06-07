# frozen_string_literal: true

module RuboCop
  module RSpec
    # Mixin for `expect_offense` and `expect_no_offenses`
    #
    # This mixin makes it easier to specify strict offense expectations
    # in a declarative and visual fashion. Just type out the code that
    # should generate a offense, annotate code by writing '^'s
    # underneath each character that should be highlighted, and follow
    # the carets with a string (separated by a space) that is the
    # message of the offense. You can include multiple offenses in
    # one code snippet.
    #
    # @example Usage
    #
    #     expect_offense(<<~RUBY)
    #       a do
    #         b
    #       end.c
    #       ^^^^^ Avoid chaining a method call on a do...end block.
    #     RUBY
    #
    # @example Equivalent assertion without `expect_offense`
    #
    #     inspect_source(<<~RUBY)
    #       a do
    #         b
    #       end.c
    #     RUBY
    #
    #     expect(rule.offenses.size).to be(1)
    #
    #     offense = rule.offenses.first
    #     expect(offense.line).to be(3)
    #     expect(offense.column_range).to be(0...5)
    #     expect(offense.message).to eql(
    #       'Avoid chaining a method call on a do...end block.'
    #     )
    #
    # Auto-correction can be tested using `expect_correction` after
    # `expect_offense`.
    #
    # @example `expect_offense` and `expect_correction`
    #
    #   expect_offense(<<~RUBY)
    #     x % 2 == 0
    #     ^^^^^^^^^^ Replace with `Integer#even?`.
    #   RUBY
    #
    #   expect_correction(<<~RUBY)
    #     x.even?
    #   RUBY
    #
    # If you do not want to specify an offense then use the
    # companion method `expect_no_offenses`. This method is a much
    # simpler assertion since it just inspects the source and checks
    # that there were no offenses. The `expect_offense` method has
    # to do more work by parsing out lines that contain carets.
    #
    # If the code produces an offense that could not be auto-corrected, you can
    # use `expect_no_corrections` after `expect_offense`.
    #
    # @example `expect_offense` and `expect_no_corrections`
    #
    #   expect_offense(<<~RUBY)
    #     a do
    #       b
    #     end.c
    #     ^^^^^ Avoid chaining a method call on a do...end block.
    #   RUBY
    #
    #   expect_no_corrections
    #
    # If your code has variables of different lengths, you can use `%{foo}`
    # and `^{foo}` to format your template:
    #
    #   %w[raise fail].each do |keyword|
    #     expect_offense(<<~RUBY, keyword: keyword)
    #       %{keyword}(RuntimeError, msg)
    #       ^{keyword}^^^^^^^^^^^^^^^^^^^ Redundant `RuntimeError` argument can be removed.
    #     RUBY
    module ExpectOffense
      def format_offense(source, **replacements)
        replacements.each do |keyword, value|
          source = source.gsub("%{#{keyword}}", value)
                         .gsub("^{#{keyword}}", '^' * value.size)
        end
        source
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def expect_offense(source, file = nil, **replacements)
        source = format_offense(source, **replacements)
        RuboCop::Formatter::DisabledConfigFormatter
          .config_to_allow_offenses = {}
        RuboCop::Formatter::DisabledConfigFormatter.detected_styles = {}
        rule.instance_variable_get(:@options)[:auto_correct] = true

        expected_annotations = AnnotatedSource.parse(source)

        if expected_annotations.plain_source == source
          raise 'Use `expect_no_offenses` to assert that no offenses are found'
        end

        @processed_source = parse_source(expected_annotations.plain_source,
                                         file)

        raise 'Error parsing example code' unless @processed_source.valid_syntax?

        _investigate(rule, @processed_source)
        actual_annotations =
          expected_annotations.with_offense_annotations(rule.offenses)

        expect(actual_annotations.to_s).to eq(expected_annotations.to_s)
      end

      def expect_correction(correction, loop: true)
        raise '`expect_correction` must follow `expect_offense`' unless @processed_source

        iteration = 0
        new_source = loop do
          iteration += 1

          corrector =
            RuboCop::Rule::Corrector.new(@processed_source.buffer, rule.corrections)
          corrected_source = corrector.rewrite

          break corrected_source unless loop
          break corrected_source if rule.corrections.empty?
          break corrected_source if corrected_source == @processed_source.buffer.source

          if iteration > RuboCop::Runner::MAX_ITERATIONS
            raise RuboCop::Runner::InfiniteCorrectionLoop.new(@processed_source.path, [])
          end

          # Prepare for next loop
          rule.instance_variable_set(:@corrections, [])
          # Cache invalidation. This is bad!
          rule.instance_variable_set(:@token_table, nil)
          @processed_source = parse_source(corrected_source,
                                           @processed_source.path)
          _investigate(rule, @processed_source)
        end

        expect(new_source).to eq(correction)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def expect_no_corrections
        raise '`expect_no_corrections` must follow `expect_offense`' unless @processed_source

        return if rule.corrections.empty?

        # In order to print a nice diff, e.g. what source got corrected to,
        # we need to run the actual corrections

        corrector =
          RuboCop::Rule::Corrector.new(@processed_source.buffer, rule.corrections)
        new_source = corrector.rewrite

        expect(new_source).to eq(@processed_source.buffer.source)
      end

      def expect_no_offenses(source, file = nil)
        inspect_source(source, file)

        expected_annotations = AnnotatedSource.parse(source)
        actual_annotations =
          expected_annotations.with_offense_annotations(rule.offenses)
        expect(actual_annotations.to_s).to eq(source)
      end

      # Parsed representation of code annotated with the `^^^ Message` style
      class AnnotatedSource
        ANNOTATION_PATTERN = /\A\s*\^+ /.freeze

        # @param annotated_source [String] string passed to the matchers
        #
        # Separates annotation lines from source lines. Tracks the real
        # source line number that each annotation corresponds to.
        #
        # @return [AnnotatedSource]
        def self.parse(annotated_source)
          source      = []
          annotations = []

          annotated_source.each_line do |source_line|
            if ANNOTATION_PATTERN.match?(source_line)
              annotations << [source.size, source_line]
            else
              source << source_line
            end
          end

          new(source, annotations)
        end

        # @param lines [Array<String>]
        # @param annotations [Array<(Integer, String)>]
        #   each entry is the annotated line number and the annotation text
        #
        # @note annotations are sorted so that reconstructing the annotation
        #   text via {#to_s} is deterministic
        def initialize(lines, annotations)
          @lines       = lines.freeze
          @annotations = annotations.sort.freeze
        end

        # Construct annotated source string (like what we parse)
        #
        # Reconstruct a deterministic annotated source string. This is
        # useful for eliminating semantically irrelevant annotation
        # ordering differences.
        #
        # @example standardization
        #
        #     source1 = AnnotatedSource.parse(<<-RUBY)
        #     line1
        #     ^ Annotation 1
        #      ^^ Annotation 2
        #     RUBY
        #
        #     source2 = AnnotatedSource.parse(<<-RUBY)
        #     line1
        #      ^^ Annotation 2
        #     ^ Annotation 1
        #     RUBY
        #
        #     source1.to_s == source2.to_s # => true
        #
        # @return [String]
        def to_s
          reconstructed = lines.dup

          annotations.reverse_each do |line_number, annotation|
            reconstructed.insert(line_number, annotation)
          end

          reconstructed.join
        end

        # Return the plain source code without annotations
        #
        # @return [String]
        def plain_source
          lines.join
        end

        # Annotate the source code with the RuboCop offenses provided
        #
        # @param offenses [Array<RuboCop::Rule::Offense>]
        #
        # @return [self]
        def with_offense_annotations(offenses)
          offense_annotations =
            offenses.map do |offense|
              indent     = ' ' * offense.column
              carets     = '^' * offense.column_length

              [offense.line, "#{indent}#{carets} #{offense.message}\n"]
            end

          self.class.new(lines, offense_annotations)
        end

        private

        attr_reader :lines, :annotations
      end
    end
  end
end
