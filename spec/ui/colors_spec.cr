require "../spec_helper"

describe Skrong::UI::Colors do
  describe ".green" do
    it "wraps text in green ANSI codes" do
      result = Skrong::UI::Colors.green("OK")
      result.should eq("\e[32mOK\e[0m")
    end
  end

  describe ".yellow" do
    it "wraps text in yellow ANSI codes" do
      result = Skrong::UI::Colors.yellow("WARN")
      result.should eq("\e[33mWARN\e[0m")
    end
  end

  describe ".red" do
    it "wraps text in red ANSI codes" do
      result = Skrong::UI::Colors.red("CRIT")
      result.should eq("\e[31mCRIT\e[0m")
    end
  end

  describe ".bold" do
    it "wraps text in bold ANSI codes" do
      result = Skrong::UI::Colors.bold("Important")
      result.should eq("\e[1mImportant\e[0m")
    end
  end

  describe ".reset" do
    it "returns the reset ANSI code" do
      Skrong::UI::Colors.reset.should eq("\e[0m")
    end
  end

  describe ".colorize" do
    it "applies color based on status type" do
      Skrong::UI::Colors.colorize("OK", :ok).should eq("\e[32mOK\e[0m")
      Skrong::UI::Colors.colorize("WARN", :warn).should eq("\e[33mWARN\e[0m")
      Skrong::UI::Colors.colorize("CRIT", :crit).should eq("\e[31mCRIT\e[0m")
    end

    it "returns plain text for unknown status" do
      Skrong::UI::Colors.colorize("UNKNOWN", :unknown).should eq("UNKNOWN")
    end
  end
end
