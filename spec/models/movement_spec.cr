require "../spec_helper"

describe Skrong::Models::Movement do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".all" do
    it "returns an empty array when no movements exist" do
      movements = Skrong::Models::Movement.all
      movements.should be_empty
    end

    it "returns all movements" do
      category = Skrong::Models::Category.all.first
      Skrong::Models::Movement.create("Bench Press", category.id)
      Skrong::Models::Movement.create("Squat", category.id)

      movements = Skrong::Models::Movement.all
      movements.size.should eq(2)
    end
  end

  describe ".find" do
    it "finds a movement by id" do
      category = Skrong::Models::Category.all.first
      created = Skrong::Models::Movement.create("Deadlift", category.id)

      found = Skrong::Models::Movement.find(created.id)

      found.should_not be_nil
      found.not_nil!.name.should eq("Deadlift")
    end

    it "returns nil for non-existent id" do
      movement = Skrong::Models::Movement.find(9999_i64)
      movement.should be_nil
    end
  end

  describe ".find_by_category" do
    it "returns movements filtered by category" do
      upper_push = Skrong::Models::Category.all.first
      upper_pull = Skrong::Models::Category.all[1]

      Skrong::Models::Movement.create("Bench Press", upper_push.id)
      Skrong::Models::Movement.create("Overhead Press", upper_push.id)
      Skrong::Models::Movement.create("Pull-ups", upper_pull.id)

      push_movements = Skrong::Models::Movement.find_by_category(upper_push.id)

      push_movements.size.should eq(2)
      push_movements.map(&.name).should contain("Bench Press")
      push_movements.map(&.name).should contain("Overhead Press")
    end

    it "returns empty array for category with no movements" do
      category = Skrong::Models::Category.all.first
      movements = Skrong::Models::Movement.find_by_category(category.id)
      movements.should be_empty
    end
  end

  describe ".create" do
    it "creates a movement with a category" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)

      movement.id.should be > 0
      movement.name.should eq("Squat")
      movement.category_id.should eq(category.id)
    end
  end

  describe "#add_target" do
    it "adds a primary target to a movement" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)
      target = Skrong::Models::Target.create("Quadriceps")

      movement.add_target(target.id, is_primary: true)

      targets = movement.targets
      targets.size.should eq(1)
      targets.first[:target_id].should eq(target.id)
      targets.first[:is_primary].should be_true
    end

    it "adds a secondary target to a movement" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)
      target = Skrong::Models::Target.create("Hamstrings")

      movement.add_target(target.id, is_primary: false)

      targets = movement.targets
      targets.first[:is_primary].should be_false
    end

    it "adds multiple targets to a movement" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      chest = Skrong::Models::Target.create("Chest")
      triceps = Skrong::Models::Target.create("Triceps")

      movement.add_target(chest.id, is_primary: true)
      movement.add_target(triceps.id, is_primary: false)

      targets = movement.targets
      targets.size.should eq(2)
    end
  end

  describe "#targets" do
    it "returns empty array when no targets are added" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Plank", category.id)

      targets = movement.targets
      targets.should be_empty
    end

    it "returns targets with is_primary flag" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)
      quads = Skrong::Models::Target.create("Quadriceps")
      glutes = Skrong::Models::Target.create("Glutes")

      movement.add_target(quads.id, is_primary: true)
      movement.add_target(glutes.id, is_primary: true)

      targets = movement.targets
      targets.size.should eq(2)
      targets.all? { |t| t[:is_primary] }.should be_true
    end
  end

  describe "#category" do
    it "returns the associated category" do
      upper_push = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Dips", upper_push.id)

      category = movement.category
      category.should_not be_nil
      category.not_nil!.name.should eq("Upper Push")
    end
  end

  describe "#to_s" do
    it "returns the movement name" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Deadlift", category.id)
      movement.to_s.should eq("Deadlift")
    end
  end
end
