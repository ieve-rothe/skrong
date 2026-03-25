require "../spec_helper"

describe Skrong::Commands::Targets do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".list" do
    it "shows message when no targets exist" do
      output = IO::Memory.new
      Skrong::Commands::Targets.list(output: output)

      output.to_s.should contain("No targets")
    end

    it "lists all targets with their properties" do
      Skrong::Models::Target.create("Chest", is_tracked: true, decay_threshold_days: 5)
      Skrong::Models::Target.create("Triceps", is_tracked: false, decay_threshold_days: 7)

      output = IO::Memory.new
      Skrong::Commands::Targets.list(output: output)

      output_str = output.to_s
      output_str.should contain("Chest")
      output_str.should contain("Triceps")
    end

    it "shows tracking status for each target" do
      Skrong::Models::Target.create("Chest", is_tracked: true)
      Skrong::Models::Target.create("Calves", is_tracked: false)

      output = IO::Memory.new
      Skrong::Commands::Targets.list(output: output)

      output_str = output.to_s
      # Should indicate which are tracked and which aren't
      (output_str.includes?("Tracked") || output_str.includes?("Yes") || output_str.includes?("No")).should be_true
    end

    it "shows decay threshold for each target" do
      Skrong::Models::Target.create("Quadriceps", decay_threshold_days: 5)

      output = IO::Memory.new
      Skrong::Commands::Targets.list(output: output)

      output.to_s.should contain("5")
    end

    it "includes target IDs for reference" do
      target = Skrong::Models::Target.create("Lats")

      output = IO::Memory.new
      Skrong::Commands::Targets.list(output: output)

      output.to_s.should contain(target.id.to_s)
    end
  end

  describe ".add" do
    it "creates a target with default values" do
      input = IO::Memory.new("Test Target\n\n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.add(input: input, output: output)

      target = Skrong::Models::Target.all.first
      target.name.should eq("Test Target")
      target.is_tracked.should be_true
      target.decay_threshold_days.should eq(5)
    end

    it "allows setting is_tracked flag" do
      input = IO::Memory.new("Test Target\nn\n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.add(input: input, output: output)

      target = Skrong::Models::Target.all.first
      target.is_tracked.should be_false
    end

    it "allows setting custom decay threshold" do
      input = IO::Memory.new("Test Target\ny\n10\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.add(input: input, output: output)

      target = Skrong::Models::Target.all.first
      target.decay_threshold_days.should eq(10)
    end

    it "shows confirmation message" do
      input = IO::Memory.new("Test Target\n\n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.add(input: input, output: output)

      output_str = output.to_s
      output_str.should contain("Target added")
      output_str.should contain("Test Target")
    end

    it "rejects empty target name" do
      input = IO::Memory.new("\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.add(input: input, output: output)

      output.to_s.should contain("cannot be empty")
      Skrong::Models::Target.all.size.should eq(0)
    end

    it "validates decay threshold is positive" do
      input = IO::Memory.new("Test Target\ny\n0\n5\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.add(input: input, output: output)

      output_str = output.to_s
      output_str.should contain("greater than 0")

      target = Skrong::Models::Target.all.first
      target.decay_threshold_days.should eq(5)
    end
  end

  describe ".delete" do
    it "deletes the target by ID" do
      target = Skrong::Models::Target.create("Test Target")

      input = IO::Memory.new("y\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.delete(target.id, input: input, output: output)

      Skrong::Models::Target.find(target.id).should be_nil
    end

    it "shows confirmation prompt" do
      target = Skrong::Models::Target.create("Test Target")

      input = IO::Memory.new("n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.delete(target.id, input: input, output: output)

      output.to_s.should contain("Are you sure")
    end

    it "cancels deletion on negative confirmation" do
      target = Skrong::Models::Target.create("Test Target")

      input = IO::Memory.new("n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.delete(target.id, input: input, output: output)

      Skrong::Models::Target.find(target.id).should_not be_nil
      output.to_s.should contain("cancelled")
    end

    it "shows error for non-existent target" do
      input = IO::Memory.new("y\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.delete(9999_i64, input: input, output: output)

      output.to_s.should contain("not found")
    end

    it "shows success message after deletion" do
      target = Skrong::Models::Target.create("Test Target")

      input = IO::Memory.new("y\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.delete(target.id, input: input, output: output)

      output.to_s.should contain("deleted")
    end
  end

  describe ".edit" do
    it "updates target name" do
      target = Skrong::Models::Target.create("Old Name")

      input = IO::Memory.new("New Name\n\n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.edit(target.id, input: input, output: output)

      updated = Skrong::Models::Target.find(target.id)
      updated.not_nil!.name.should eq("New Name")
    end

    it "updates is_tracked status" do
      target = Skrong::Models::Target.create("Test", is_tracked: true)

      input = IO::Memory.new("\nn\n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.edit(target.id, input: input, output: output)

      updated = Skrong::Models::Target.find(target.id)
      updated.not_nil!.is_tracked.should be_false
    end

    it "updates decay threshold" do
      target = Skrong::Models::Target.create("Test", decay_threshold_days: 5)

      input = IO::Memory.new("\n\n10\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.edit(target.id, input: input, output: output)

      updated = Skrong::Models::Target.find(target.id)
      updated.not_nil!.decay_threshold_days.should eq(10)
    end

    it "allows keeping existing values" do
      target = Skrong::Models::Target.create("Test", is_tracked: true, decay_threshold_days: 7)

      input = IO::Memory.new("\n\n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.edit(target.id, input: input, output: output)

      updated = Skrong::Models::Target.find(target.id)
      updated.not_nil!.name.should eq("Test")
      updated.not_nil!.is_tracked.should be_true
      updated.not_nil!.decay_threshold_days.should eq(7)
    end

    it "shows error for non-existent target" do
      input = IO::Memory.new("\n\n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.edit(9999_i64, input: input, output: output)

      output.to_s.should contain("not found")
    end

    it "shows success message after update" do
      target = Skrong::Models::Target.create("Test")

      input = IO::Memory.new("\n\n\n")
      output = IO::Memory.new

      Skrong::Commands::Targets.edit(target.id, input: input, output: output)

      output.to_s.should contain("updated")
    end
  end
end
