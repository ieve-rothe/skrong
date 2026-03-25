require "../spec_helper"

describe Skrong::Commands::Library do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".list" do
    it "displays message when no movements exist" do
      output = IO::Memory.new
      Skrong::Commands::Library.list(output: output)

      output.to_s.should contain("No movements")
    end

    it "lists movements grouped by category" do
      category1 = Skrong::Models::Category.all.first
      category2 = Skrong::Models::Category.all[1]

      Skrong::Models::Movement.create("Bench Press", category1.id)
      Skrong::Models::Movement.create("Overhead Press", category1.id)
      Skrong::Models::Movement.create("Pull-ups", category2.id)

      output = IO::Memory.new
      Skrong::Commands::Library.list(output: output)

      output_str = output.to_s
      output_str.should contain("Upper Push")
      output_str.should contain("Bench Press")
      output_str.should contain("Overhead Press")
      output_str.should contain("Upper Pull")
      output_str.should contain("Pull-ups")
    end

    it "shows targets for each movement" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)

      target1 = Skrong::Models::Target.create("Chest")
      target2 = Skrong::Models::Target.create("Triceps")

      movement.add_target(target1.id, is_primary: true)
      movement.add_target(target2.id, is_primary: false)

      output = IO::Memory.new
      Skrong::Commands::Library.list(output: output)

      output_str = output.to_s
      output_str.should contain("Chest")
      output_str.should contain("Triceps")
    end

    it "shows movement IDs for reference" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)

      output = IO::Memory.new
      Skrong::Commands::Library.list(output: output)

      output.to_s.should contain("[#{movement.id}]")
    end
  end

  describe ".add" do
    it "adds a movement with category and targets" do
      # Input: category selection, name, target selection (done)
      input = IO::Memory.new("1\nBench Press\n1\ndone\n")
      output = IO::Memory.new

      # Create a target first
      Skrong::Models::Target.create("Chest")

      Skrong::Commands::Library.add(input: input, output: output)

      movements = Skrong::Models::Movement.all
      movements.size.should eq(1)
      movements.first.name.should eq("Bench Press")
    end

    it "prompts for category" do
      input = IO::Memory.new("1\nSquat\ndone\n")
      output = IO::Memory.new

      Skrong::Commands::Library.add(input: input, output: output)

      output.to_s.should contain("Select category")
    end

    it "prompts for movement name" do
      input = IO::Memory.new("1\nDeadlift\ndone\n")
      output = IO::Memory.new

      Skrong::Commands::Library.add(input: input, output: output)

      output.to_s.should contain("Enter movement name")
    end

    it "allows adding multiple targets" do
      input = IO::Memory.new("1\nBench Press\n1\n2\ndone\n")
      output = IO::Memory.new

      chest = Skrong::Models::Target.create("Chest")
      triceps = Skrong::Models::Target.create("Triceps")

      Skrong::Commands::Library.add(input: input, output: output)

      movement = Skrong::Models::Movement.all.first
      targets = movement.targets
      targets.size.should eq(2)
    end

    it "handles no targets gracefully" do
      input = IO::Memory.new("1\nPlank\ndone\n")
      output = IO::Memory.new

      Skrong::Commands::Library.add(input: input, output: output)

      movements = Skrong::Models::Movement.all
      movements.size.should eq(1)
      movements.first.targets.should be_empty
    end

    it "shows success message" do
      input = IO::Memory.new("1\nSquat\ndone\n")
      output = IO::Memory.new

      Skrong::Commands::Library.add(input: input, output: output)

      output.to_s.should contain("Movement added")
    end
  end

  describe ".delete" do
    it "deletes a movement by ID" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("To Delete", category.id)

      # Input: confirm deletion
      input = IO::Memory.new("y\n")
      output = IO::Memory.new

      Skrong::Commands::Library.delete(movement.id, input: input, output: output)

      Skrong::Models::Movement.all.should be_empty
    end

    it "prompts for confirmation" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("To Delete", category.id)

      input = IO::Memory.new("y\n")
      output = IO::Memory.new

      Skrong::Commands::Library.delete(movement.id, input: input, output: output)

      output.to_s.should contain("Are you sure")
      output.to_s.should contain("To Delete")
    end

    it "cancels deletion if user declines" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Keep This", category.id)

      input = IO::Memory.new("n\n")
      output = IO::Memory.new

      Skrong::Commands::Library.delete(movement.id, input: input, output: output)

      Skrong::Models::Movement.all.size.should eq(1)
    end

    it "shows error for non-existent movement" do
      output = IO::Memory.new

      Skrong::Commands::Library.delete(9999_i64, output: output)

      output.to_s.should contain("not found")
    end

    it "shows success message after deletion" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("To Delete", category.id)

      input = IO::Memory.new("y\n")
      output = IO::Memory.new

      Skrong::Commands::Library.delete(movement.id, input: input, output: output)

      output.to_s.should contain("deleted")
    end
  end
end
