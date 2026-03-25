require "../spec_helper"

describe Skrong::DB::Migrations do
  before_each do
    # Reset connection and use a test database
    Skrong::DB::Connection.reset!

    # Clean up any existing test database
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
  end

  describe ".run" do
    it "creates the categories table" do
      Skrong::DB::Migrations.run

      db = Skrong::DB::Connection.instance
      result = db.query_one("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='categories'", as: Int32)
      result.should eq(1)
    end

    it "creates the targets table" do
      Skrong::DB::Migrations.run

      db = Skrong::DB::Connection.instance
      result = db.query_one("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='targets'", as: Int32)
      result.should eq(1)
    end

    it "creates the movements table" do
      Skrong::DB::Migrations.run

      db = Skrong::DB::Connection.instance
      result = db.query_one("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='movements'", as: Int32)
      result.should eq(1)
    end

    it "creates the movement_targets junction table" do
      Skrong::DB::Migrations.run

      db = Skrong::DB::Connection.instance
      result = db.query_one("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='movement_targets'", as: Int32)
      result.should eq(1)
    end

    it "creates the sessions table" do
      Skrong::DB::Migrations.run

      db = Skrong::DB::Connection.instance
      result = db.query_one("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='sessions'", as: Int32)
      result.should eq(1)
    end

    it "creates the sets table" do
      Skrong::DB::Migrations.run

      db = Skrong::DB::Connection.instance
      result = db.query_one("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='sets'", as: Int32)
      result.should eq(1)
    end

    it "creates index on movement_targets" do
      Skrong::DB::Migrations.run

      db = Skrong::DB::Connection.instance
      result = db.query_one("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_movement_targets_unique'", as: Int32)
      result.should eq(1)
    end

    it "seeds the 6 default categories" do
      Skrong::DB::Migrations.run

      db = Skrong::DB::Connection.instance
      count = db.query_one("SELECT COUNT(*) FROM categories", as: Int32)
      count.should eq(6)
    end

    it "seeds categories with correct names and order" do
      Skrong::DB::Migrations.run

      db = Skrong::DB::Connection.instance
      categories = [] of String
      db.query("SELECT name FROM categories ORDER BY display_order") do |rs|
        rs.each do
          categories << rs.read(String)
        end
      end

      categories.should eq([
        "Upper Push",
        "Upper Pull",
        "Lower Hinge",
        "Lower Squat",
        "Armor & Isolation",
        "Core & Stability"
      ])
    end

    it "is idempotent (can run multiple times)" do
      Skrong::DB::Migrations.run

      # Running again should not raise an error
      Skrong::DB::Migrations.run

      # And category count should still be 6 (not 12)
      db = Skrong::DB::Connection.instance
      count = db.query_one("SELECT COUNT(*) FROM categories", as: Int32)
      count.should eq(6)
    end
  end
end
