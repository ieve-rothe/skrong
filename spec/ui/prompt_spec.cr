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

  describe ".parse_endurance_payload" do
    it "parses valid distance duration rpe (MM:SS)" do
      result = Skrong::UI::Prompt.parse_endurance_payload("3.1 24:30 7")
      result.should eq({distance: 3.1, duration_seconds: 1470, rpe: 7})
    end

    it "parses valid distance duration rpe (HH:MM:SS)" do
      result = Skrong::UI::Prompt.parse_endurance_payload("13.1 1:45:00 8")
      result.should eq({distance: 13.1, duration_seconds: 6300, rpe: 8})
    end

    it "parses single-digit minute duration (M:SS)" do
      result = Skrong::UI::Prompt.parse_endurance_payload("1.5 8:30 6")
      result.should eq({distance: 1.5, duration_seconds: 510, rpe: 6})
    end

    it "parses integer distance" do
      result = Skrong::UI::Prompt.parse_endurance_payload("5 40:00 7")
      result.should eq({distance: 5.0, duration_seconds: 2400, rpe: 7})
    end

    it "raises error for invalid format (too few values)" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Invalid format") do
        Skrong::UI::Prompt.parse_endurance_payload("3.1 24:30")
      end
    end

    it "raises error for negative distance" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Distance must be a positive number") do
        Skrong::UI::Prompt.parse_endurance_payload("-3.1 24:30 7")
      end
    end

    it "raises error for zero distance" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Distance must be a positive number") do
        Skrong::UI::Prompt.parse_endurance_payload("0 24:30 7")
      end
    end

    it "raises error for invalid duration format" do
      expect_raises(Skrong::UI::Prompt::ParseError, "Duration must be in MM:SS or HH:MM:SS format") do
        Skrong::UI::Prompt.parse_endurance_payload("3.1 24 7")
      end
    end

    it "raises error for RPE out of range" do
      expect_raises(Skrong::UI::Prompt::ParseError, "RPE must be an integer between 1 and 10") do
        Skrong::UI::Prompt.parse_endurance_payload("3.1 24:30 11")
      end
    end
  end

  describe ".parse_set_payload" do
    it "parses strength payload when activity_type is strength" do
      result = Skrong::UI::Prompt.parse_set_payload("strength", "185 8 7")
      result[:weight].should eq(185.0)
      result[:reps].should eq(8)
      result[:rpe].should eq(7)
      result[:distance].should be_nil
      result[:duration_seconds].should be_nil
    end

    it "parses endurance payload when activity_type is endurance" do
      result = Skrong::UI::Prompt.parse_set_payload("endurance", "3.1 24:30 7")
      result[:weight].should be_nil
      result[:reps].should be_nil
      result[:rpe].should eq(7)
      result[:distance].should eq(3.1)
      result[:duration_seconds].should eq(1470)
    end

    it "defaults to strength for unknown activity_type" do
      result = Skrong::UI::Prompt.parse_set_payload("unknown", "185 8 7")
      result[:weight].should eq(185.0)
    end
  end
end
