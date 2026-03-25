require "../spec_helper"

describe Skrong::UI::Prompt do
  describe ".parse_payload" do
    it "parses valid space-delimited payload" do
      result = Skrong::UI::Prompt.parse_payload("40 15 8")
      result.should eq({weight: 40.0, reps: 15, rpe: 8})
    end

    it "parses decimal weight values" do
      result = Skrong::UI::Prompt.parse_payload("135.5 5 9")
      result.should eq({weight: 135.5, reps: 5, rpe: 9})
    end

    it "parses large weight values" do
      result = Skrong::UI::Prompt.parse_payload("225 3 10")
      result.should eq({weight: 225.0, reps: 3, rpe: 10})
    end

    it "raises error for invalid format (too few values)" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Invalid format") do
        Skrong::UI::Prompt.parse_payload("40 15")
      end
    end

    it "raises error for invalid format (too many values)" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Invalid format") do
        Skrong::UI::Prompt.parse_payload("40 15 8 extra")
      end
    end

    it "raises error for non-numeric weight" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Weight must be a positive number") do
        Skrong::UI::Prompt.parse_payload("abc 15 8")
      end
    end

    it "raises error for negative weight" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Weight must be a positive number") do
        Skrong::UI::Prompt.parse_payload("-40 15 8")
      end
    end

    it "raises error for zero weight" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Weight must be a positive number") do
        Skrong::UI::Prompt.parse_payload("0 15 8")
      end
    end

    it "raises error for non-integer reps" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Reps must be a positive integer") do
        Skrong::UI::Prompt.parse_payload("40 15.5 8")
      end
    end

    it "raises error for negative reps" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Reps must be a positive integer") do
        Skrong::UI::Prompt.parse_payload("40 -15 8")
      end
    end

    it "raises error for zero reps" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Reps must be a positive integer") do
        Skrong::UI::Prompt.parse_payload("40 0 8")
      end
    end

    it "raises error for non-integer RPE" do
      expect_raises(Skrong::UI::Prompt::ParseError, "RPE must be an integer between 1 and 10") do
        Skrong::UI::Prompt.parse_payload("40 15 8.5")
      end
    end

    it "raises error for RPE below 1" do
      expect_raises(Skrong::UI::Prompt::ParseError, "RPE must be an integer between 1 and 10") do
        Skrong::UI::Prompt.parse_payload("40 15 0")
      end
    end

    it "raises error for RPE above 10" do
      expect_raises(Skrong::UI::Prompt::ParseError, "RPE must be an integer between 1 and 10") do
        Skrong::UI::Prompt.parse_payload("40 15 11")
      end
    end
  end

  describe ".parse_date" do
    it "parses valid YYYY-MM-DD date" do
      result = Skrong::UI::Prompt.parse_date("2026-03-24")
      result.should eq(Time.local(2026, 3, 24))
    end

    it "raises error for invalid format" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Invalid date format") do
        Skrong::UI::Prompt.parse_date("03/24/2026")
      end
    end

    it "raises error for invalid date (month)" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Invalid date") do
        Skrong::UI::Prompt.parse_date("2026-13-01")
      end
    end

    it "raises error for invalid date (day)" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Invalid date") do
        Skrong::UI::Prompt.parse_date("2026-02-30")
      end
    end

    it "raises error for empty string" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Invalid date format") do
        Skrong::UI::Prompt.parse_date("")
      end
    end
  end

  describe ".validate_payload_format" do
    it "returns true for valid format example" do
      Skrong::UI::Prompt.validate_payload_format("40 15 8").should be_true
    end

    it "returns false for invalid format" do
      Skrong::UI::Prompt.validate_payload_format("invalid").should be_false
    end
  end

  describe ".payload_format_example" do
    it "returns format example string" do
      example = Skrong::UI::Prompt.payload_format_example
      example.should contain("weight")
      example.should contain("reps")
      example.should contain("rpe")
    end
  end
end
