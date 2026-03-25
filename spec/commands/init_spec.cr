require "../spec_helper"

describe Skrong::Commands::Init do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
  end

  describe ".run" do
    it "initializes the database" do
      output = IO::Memory.new
      Skrong::Commands::Init.run(output: output)

      # Verify database file was created
      File.exists?(Skrong::DB::Connection.db_path).should be_true
    end

    it "creates all tables" do
      output = IO::Memory.new
      Skrong::Commands::Init.run(output: output)

      db = Skrong::DB::Connection.instance

      # Check all tables exist
      tables = ["categories", "targets", "movements", "movement_targets", "sessions", "sets"]
      tables.each do |table|
        count = db.query_one("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=?", table, as: Int32)
        count.should eq(1)
      end
    end

    it "seeds default categories" do
      output = IO::Memory.new
      Skrong::Commands::Init.run(output: output)

      categories = Skrong::Models::Category.all
      categories.size.should eq(6)

      expected_names = [
        "Upper Push",
        "Upper Pull",
        "Lower Hinge",
        "Lower Squat",
        "Armor & Isolation",
        "Core & Stability"
      ]

      categories.map(&.name).should eq(expected_names)
    end

    it "outputs success message" do
      output = IO::Memory.new
      Skrong::Commands::Init.run(output: output)

      output.to_s.should contain("Database initialized")
    end

    it "is idempotent (can run multiple times)" do
      output = IO::Memory.new

      Skrong::Commands::Init.run(output: output)
      Skrong::Commands::Init.run(output: output)

      # Should still have exactly 6 categories
      categories = Skrong::Models::Category.all
      categories.size.should eq(6)
    end

    it "outputs already initialized message on subsequent runs" do
      output1 = IO::Memory.new
      output2 = IO::Memory.new

      Skrong::Commands::Init.run(output: output1)
      Skrong::Commands::Init.run(output: output2)

      output2.to_s.should contain("already initialized")
    end
  end
end
