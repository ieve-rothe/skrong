require "../spec_helper"

describe Skrong::Models::Target do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".all" do
    it "returns an empty array when no targets exist" do
      targets = Skrong::Models::Target.all
      targets.should be_empty
    end

    it "returns all targets" do
      Skrong::Models::Target.create("Quadriceps")
      Skrong::Models::Target.create("Hamstrings")

      targets = Skrong::Models::Target.all
      targets.size.should eq(2)
    end
  end

  describe ".tracked" do
    it "returns only tracked targets" do
      Skrong::Models::Target.create("Quadriceps", is_tracked: true)
      Skrong::Models::Target.create("Calves", is_tracked: false)

      tracked = Skrong::Models::Target.tracked
      tracked.size.should eq(1)
      tracked.first.name.should eq("Quadriceps")
    end
  end

  describe ".find" do
    it "finds a target by id" do
      created = Skrong::Models::Target.create("Glutes")
      found = Skrong::Models::Target.find(created.id)

      found.should_not be_nil
      found.not_nil!.name.should eq("Glutes")
    end

    it "returns nil for non-existent id" do
      target = Skrong::Models::Target.find(9999_i64)
      target.should be_nil
    end
  end

  describe ".create" do
    it "creates a target with default values" do
      target = Skrong::Models::Target.create("Chest")

      target.id.should be > 0
      target.name.should eq("Chest")
      target.is_tracked.should be_true
      target.decay_threshold_days.should eq(5)
    end

    it "creates a target with custom values" do
      target = Skrong::Models::Target.create(
        "Rotator Cuff",
        is_tracked: false,
        decay_threshold_days: 7
      )

      target.is_tracked.should be_false
      target.decay_threshold_days.should eq(7)
    end
  end

  describe "#update" do
    it "updates target attributes" do
      target = Skrong::Models::Target.create("Lats")

      target.update(is_tracked: false, decay_threshold_days: 10)

      updated = Skrong::Models::Target.find(target.id).not_nil!
      updated.is_tracked.should be_false
      updated.decay_threshold_days.should eq(10)
    end

    it "updates target name" do
      target = Skrong::Models::Target.create("Old Name")

      target.update(name: "New Name")

      updated = Skrong::Models::Target.find(target.id).not_nil!
      updated.name.should eq("New Name")
    end
  end

  describe "#to_s" do
    it "returns the target name" do
      target = Skrong::Models::Target.create("Triceps")
      target.to_s.should eq("Triceps")
    end
  end
end
