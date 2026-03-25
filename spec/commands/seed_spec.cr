require "../spec_helper"

describe Skrong::Commands::Seed do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".import_targets" do
    it "imports targets from a valid seed file" do
      seed_content = <<-SEED
      # Test Section
      - name: "Test Target 1"
        decay_threshold_days: 5
      - name: "Test Target 2"
        decay_threshold_days: 7
      SEED

      File.write("/tmp/test_targets_seed.md", seed_content)

      output = IO::Memory.new
      Skrong::Commands::Seed.import_targets("/tmp/test_targets_seed.md", output: output)

      targets = Skrong::Models::Target.all
      targets.size.should eq(2)
      targets[0].name.should eq("Test Target 1")
      targets[0].decay_threshold_days.should eq(5)
      targets[1].name.should eq("Test Target 2")
      targets[1].decay_threshold_days.should eq(7)

      File.delete("/tmp/test_targets_seed.md")
    end

    it "defaults is_tracked to true for all imported targets" do
      seed_content = <<-SEED
      - name: "Tracked Target"
        decay_threshold_days: 5
      SEED

      File.write("/tmp/test_targets_seed.md", seed_content)

      output = IO::Memory.new
      Skrong::Commands::Seed.import_targets("/tmp/test_targets_seed.md", output: output)

      target = Skrong::Models::Target.all.first
      target.is_tracked.should be_true

      File.delete("/tmp/test_targets_seed.md")
    end

    it "skips comment lines and section headers" do
      seed_content = <<-SEED
      # THE CORE
      - name: "Core Target"
        decay_threshold_days: 3
      # Another comment
      SEED

      File.write("/tmp/test_targets_seed.md", seed_content)

      output = IO::Memory.new
      Skrong::Commands::Seed.import_targets("/tmp/test_targets_seed.md", output: output)

      targets = Skrong::Models::Target.all
      targets.size.should eq(1)

      File.delete("/tmp/test_targets_seed.md")
    end

    it "handles names with parenthetical notes" do
      seed_content = <<-SEED
      - name: "Pectorals" (Chest)
        decay_threshold_days: 5
      SEED

      File.write("/tmp/test_targets_seed.md", seed_content)

      output = IO::Memory.new
      Skrong::Commands::Seed.import_targets("/tmp/test_targets_seed.md", output: output)

      target = Skrong::Models::Target.all.first
      target.name.should eq("Pectorals")

      File.delete("/tmp/test_targets_seed.md")
    end

    it "handles inline comments after decay_threshold_days" do
      seed_content = <<-SEED
      - name: "Spinal Erectors" # Lower back
        decay_threshold_days: 5 # Important!
      SEED

      File.write("/tmp/test_targets_seed.md", seed_content)

      output = IO::Memory.new
      Skrong::Commands::Seed.import_targets("/tmp/test_targets_seed.md", output: output)

      target = Skrong::Models::Target.all.first
      target.name.should eq("Spinal Erectors")
      target.decay_threshold_days.should eq(5)

      File.delete("/tmp/test_targets_seed.md")
    end

    it "shows import summary" do
      seed_content = <<-SEED
      - name: "Test Target"
        decay_threshold_days: 5
      SEED

      File.write("/tmp/test_targets_seed.md", seed_content)

      output = IO::Memory.new
      Skrong::Commands::Seed.import_targets("/tmp/test_targets_seed.md", output: output)

      output_str = output.to_s
      output_str.should contain("Importing targets")
      output_str.should contain("imported successfully")

      File.delete("/tmp/test_targets_seed.md")
    end

    it "shows error for non-existent file" do
      output = IO::Memory.new
      Skrong::Commands::Seed.import_targets("/tmp/nonexistent.md", output: output)

      output.to_s.should contain("File not found")
    end

    it "skips targets that already exist" do
      Skrong::Models::Target.create("Existing Target", decay_threshold_days: 3)

      seed_content = <<-SEED
      - name: "Existing Target"
        decay_threshold_days: 5
      - name: "New Target"
        decay_threshold_days: 7
      SEED

      File.write("/tmp/test_targets_seed.md", seed_content)

      output = IO::Memory.new
      Skrong::Commands::Seed.import_targets("/tmp/test_targets_seed.md", output: output)

      targets = Skrong::Models::Target.all
      targets.size.should eq(2)

      # Existing target should retain original decay threshold
      existing = targets.find { |t| t.name == "Existing Target" }.not_nil!
      existing.decay_threshold_days.should eq(3)

      output_str = output.to_s
      output_str.should contain("skipped")

      File.delete("/tmp/test_targets_seed.md")
    end

    it "defaults decay_threshold_days to 5 if not specified" do
      seed_content = <<-SEED
      - name: "Default Threshold Target"
      SEED

      File.write("/tmp/test_targets_seed.md", seed_content)

      output = IO::Memory.new
      Skrong::Commands::Seed.import_targets("/tmp/test_targets_seed.md", output: output)

      target = Skrong::Models::Target.all.first
      target.decay_threshold_days.should eq(5)

      File.delete("/tmp/test_targets_seed.md")
    end
  end

  describe ".import_movements" do
    it "imports movements from a valid seed file" do
      seed_content = <<-SEED
      # Upper Push
      - name: "Bench Press"
        category: "Upper Push"
        targets:
          - "Pectorals"
          - "Triceps"
      - name: "Overhead Press"
        category: "Upper Push"
        targets:
          - "Anterior Deltoids"
      SEED

      File.write("/tmp/test_movements_seed.md", seed_content)

      # Create required targets and category
      Skrong::Models::Target.create("Pectorals")
      Skrong::Models::Target.create("Triceps")
      Skrong::Models::Target.create("Anterior Deltoids")

      output = IO::Memory.new
      Skrong::Commands::Seed.import_movements("/tmp/test_movements_seed.md", output: output)

      movements = Skrong::Models::Movement.all
      movements.size.should eq(2)
      movements[0].name.should eq("Bench Press")
      movements[1].name.should eq("Overhead Press")

      File.delete("/tmp/test_movements_seed.md")
    end

    it "associates movements with targets" do
      seed_content = <<-SEED
      - name: "Squat"
        category: "Lower Squat"
        targets:
          - "Quadriceps"
          - "Gluteus Maximus"
      SEED

      File.write("/tmp/test_movements_seed.md", seed_content)

      quads = Skrong::Models::Target.create("Quadriceps")
      glutes = Skrong::Models::Target.create("Gluteus Maximus")

      output = IO::Memory.new
      Skrong::Commands::Seed.import_movements("/tmp/test_movements_seed.md", output: output)

      movement = Skrong::Models::Movement.all.first
      movement_targets = movement.targets
      movement_targets.size.should eq(2)

      File.delete("/tmp/test_movements_seed.md")
    end

    it "creates movements in the correct category" do
      seed_content = <<-SEED
      - name: "Deadlift"
        category: "Lower Hinge"
        targets:
          - "Hamstrings"
      SEED

      File.write("/tmp/test_movements_seed.md", seed_content)

      Skrong::Models::Target.create("Hamstrings")

      output = IO::Memory.new
      Skrong::Commands::Seed.import_movements("/tmp/test_movements_seed.md", output: output)

      movement = Skrong::Models::Movement.all.first
      category = Skrong::Models::Category.all.find { |c| c.id == movement.category_id }.not_nil!
      category.name.should eq("Lower Hinge")

      File.delete("/tmp/test_movements_seed.md")
    end

    it "skips movements that already exist" do
      category = Skrong::Models::Category.all.first
      Skrong::Models::Movement.create("Existing Movement", category.id)

      seed_content = <<-SEED
      - name: "Existing Movement"
        category: "Upper Push"
        targets:
          - "Pectorals"
      SEED

      File.write("/tmp/test_movements_seed.md", seed_content)

      Skrong::Models::Target.create("Pectorals")

      output = IO::Memory.new
      Skrong::Commands::Seed.import_movements("/tmp/test_movements_seed.md", output: output)

      movements = Skrong::Models::Movement.all
      movements.size.should eq(1)

      output_str = output.to_s
      output_str.should contain("skipped")

      File.delete("/tmp/test_movements_seed.md")
    end

    it "shows error for non-existent category" do
      seed_content = <<-SEED
      - name: "Test Movement"
        category: "Nonexistent Category"
        targets:
          - "Pectorals"
      SEED

      File.write("/tmp/test_movements_seed.md", seed_content)

      Skrong::Models::Target.create("Pectorals")

      output = IO::Memory.new
      Skrong::Commands::Seed.import_movements("/tmp/test_movements_seed.md", output: output)

      output_str = output.to_s
      output_str.should contain("Category not found")

      File.delete("/tmp/test_movements_seed.md")
    end

    it "shows warning for non-existent targets" do
      seed_content = <<-SEED
      - name: "Test Movement"
        category: "Upper Push"
        targets:
          - "Nonexistent Target"
      SEED

      File.write("/tmp/test_movements_seed.md", seed_content)

      output = IO::Memory.new
      Skrong::Commands::Seed.import_movements("/tmp/test_movements_seed.md", output: output)

      output_str = output.to_s
      output_str.should contain("Target not found")

      File.delete("/tmp/test_movements_seed.md")
    end

    it "shows import summary" do
      seed_content = <<-SEED
      - name: "Test Movement"
        category: "Upper Push"
        targets:
          - "Pectorals"
      SEED

      File.write("/tmp/test_movements_seed.md", seed_content)

      Skrong::Models::Target.create("Pectorals")

      output = IO::Memory.new
      Skrong::Commands::Seed.import_movements("/tmp/test_movements_seed.md", output: output)

      output_str = output.to_s
      output_str.should contain("Importing movements")
      output_str.should contain("imported successfully")

      File.delete("/tmp/test_movements_seed.md")
    end
  end
end
