# frozen_string_literal: true

RSpec.describe RuboCop::Rule::Style::SelfAssignment do
  subject(:rule) { described_class.new }

  %i[+ - * ** / | & || &&].product(['x', '@x', '@@x']).each do |op, var|
    it "registers an offense for non-shorthand assignment #{op} and #{var}" do
      inspect_source("#{var} = #{var} #{op} y")
      expect(rule.offenses.size).to eq(1)
      expect(rule.messages)
        .to eq(["Use self-assignment shorthand `#{op}=`."])
    end

    it "accepts shorthand assignment for #{op} and #{var}" do
      expect_no_offenses("#{var} #{op}= y")
    end

    it "auto-corrects a non-shorthand assignment #{op} and #{var}" do
      new_source = autocorrect_source("#{var} = #{var} #{op} y")
      expect(new_source).to eq("#{var} #{op}= y")
    end
  end
end
