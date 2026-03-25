require "../spec_helper"

describe Skrong::UI::Select do
  describe ".render_list" do
    it "renders a numbered list of items" do
      items = ["Option 1", "Option 2", "Option 3"]
      output = Skrong::UI::Select.render_list(items, title: "Select an option:")

      output.should contain("Select an option:")
      output.should contain("  1. Option 1")
      output.should contain("  2. Option 2")
      output.should contain("  3. Option 3")
    end

    it "handles empty list" do
      items = [] of String
      output = Skrong::UI::Select.render_list(items, title: "Empty:")

      output.should contain("Empty:")
      output.should_not contain("1.")
    end

    it "handles single item" do
      items = ["Only Option"]
      output = Skrong::UI::Select.render_list(items, title: "Choose:")

      output.should contain("  1. Only Option")
    end

    it "renders list without title" do
      items = ["A", "B"]
      output = Skrong::UI::Select.render_list(items)

      output.should contain("  1. A")
      output.should contain("  2. B")
      output.lines.first.should_not eq("")  # Should start with items
    end
  end

  describe ".parse_selection" do
    it "parses valid number input" do
      result = Skrong::UI::Select.parse_selection("2", max: 5)
      result.should eq(2)
    end

    it "parses number with whitespace" do
      result = Skrong::UI::Select.parse_selection("  3  ", max: 5)
      result.should eq(3)
    end

    it "returns nil for non-numeric input" do
      result = Skrong::UI::Select.parse_selection("abc", max: 5)
      result.should be_nil
    end

    it "returns nil for number below 1" do
      result = Skrong::UI::Select.parse_selection("0", max: 5)
      result.should be_nil
    end

    it "returns nil for number above max" do
      result = Skrong::UI::Select.parse_selection("6", max: 5)
      result.should be_nil
    end

    it "returns nil for empty string" do
      result = Skrong::UI::Select.parse_selection("", max: 5)
      result.should be_nil
    end

    it "handles edge case of max boundary" do
      result = Skrong::UI::Select.parse_selection("5", max: 5)
      result.should eq(5)
    end

    it "handles edge case of min boundary" do
      result = Skrong::UI::Select.parse_selection("1", max: 5)
      result.should eq(1)
    end
  end

  describe ".validate_selection" do
    it "returns true for valid selection" do
      Skrong::UI::Select.validate_selection(3, max: 5).should be_true
    end

    it "returns false for selection below 1" do
      Skrong::UI::Select.validate_selection(0, max: 5).should be_false
    end

    it "returns false for selection above max" do
      Skrong::UI::Select.validate_selection(6, max: 5).should be_false
    end

    it "returns true for boundary values" do
      Skrong::UI::Select.validate_selection(1, max: 5).should be_true
      Skrong::UI::Select.validate_selection(5, max: 5).should be_true
    end
  end

  describe ".prompt_text" do
    it "returns prompt with number range" do
      prompt = Skrong::UI::Select.prompt_text(5)
      prompt.should contain("1")
      prompt.should contain("5")
    end

    it "handles single option" do
      prompt = Skrong::UI::Select.prompt_text(1)
      prompt.should contain("1")
    end
  end
end
