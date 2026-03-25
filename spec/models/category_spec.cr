require "../spec_helper"

describe Skrong::Models::Category do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".all" do
    it "returns all categories ordered by display_order" do
      categories = Skrong::Models::Category.all

      categories.size.should eq(6)
      categories.first.name.should eq("Upper Push")
      categories.last.name.should eq("Core & Stability")
    end

    it "returns categories with correct attributes" do
      category = Skrong::Models::Category.all.first

      category.id.should be_a(Int64)
      category.name.should be_a(String)
      category.display_order.should be_a(Int32)
    end
  end

  describe ".find" do
    it "finds a category by id" do
      # Get the first category's ID
      all_categories = Skrong::Models::Category.all
      first_id = all_categories.first.id

      category = Skrong::Models::Category.find(first_id)

      category.should_not be_nil
      category.not_nil!.name.should eq("Upper Push")
    end

    it "returns nil for non-existent id" do
      category = Skrong::Models::Category.find(9999_i64)
      category.should be_nil
    end
  end

  describe ".create" do
    it "creates a new category" do
      initial_count = Skrong::Models::Category.all.size

      category = Skrong::Models::Category.create(
        name: "Custom Category",
        display_order: 7
      )

      category.id.should be > 0
      category.name.should eq("Custom Category")
      category.display_order.should eq(7)

      Skrong::Models::Category.all.size.should eq(initial_count + 1)
    end
  end

  describe "#to_s" do
    it "returns the category name" do
      category = Skrong::Models::Category.all.first
      category.to_s.should eq(category.name)
    end
  end
end
