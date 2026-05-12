require "../spec_helper"

describe Skrong::Commands::Export do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".export_targets" do
    it "exports targets to a file" do
      Skrong::Models::Target.create("Test Target 1", decay_threshold_days: 5)
      Skrong::Models::Target.create("Test Target 2", decay_threshold_days: 7)

      output = IO::Memory.new
      Skrong::Commands::Export.export_targets("/tmp/test_export_targets.md", output: output)

      File.exists?("/tmp/test_export_targets.md").should be_true

      content = File.read("/tmp/test_export_targets.md")
      content.should contain("- name: \"Test Target 1\"")
      content.should contain("  decay_threshold_days: 5")
      content.should contain("- name: \"Test Target 2\"")
      content.should contain("  decay_threshold_days: 7")

      File.delete("/tmp/test_export_targets.md")
    end

    it "shows export summary" do
      Skrong::Models::Target.create("Test Target", decay_threshold_days: 5)

      output = IO::Memory.new
      Skrong::Commands::Export.export_targets("/tmp/test_export_targets.md", output: output)

      output_str = output.to_s
      output_str.should contain("Exporting")
      output_str.should contain("exported successfully")

      File.delete("/tmp/test_export_targets.md")
    end

    it "handles empty targets list" do
      output = IO::Memory.new
      Skrong::Commands::Export.export_targets("/tmp/test_export_targets.md", output: output)

      output_str = output.to_s
      output_str.should contain("No targets to export")
    end
  end

  describe ".export_movements" do
    it "exports movements to a file" do
      # Create targets
      pecs = Skrong::Models::Target.create("Pectorals", decay_threshold_days: 5)
      triceps = Skrong::Models::Target.create("Triceps", decay_threshold_days: 4)

      # Create movement
      category = Skrong::Models::Category.all.find { |c| c.name == "Upper Push" }.not_nil!
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      movement.add_target(pecs.id)
      movement.add_target(triceps.id)

      output = IO::Memory.new
      Skrong::Commands::Export.export_movements("/tmp/test_export_movements.md", output: output)

      File.exists?("/tmp/test_export_movements.md").should be_true

      content = File.read("/tmp/test_export_movements.md")
      content.should contain("# UPPER PUSH")
      content.should contain("- name: \"Bench Press\"")
      content.should contain("  category: \"Upper Push\"")
      content.should contain("  targets:")
      content.should contain("    - \"Pectorals\"")
      content.should contain("    - \"Triceps\"")

      File.delete("/tmp/test_export_movements.md")
    end

    it "groups movements by category" do
      # Create targets
      quads = Skrong::Models::Target.create("Quadriceps", decay_threshold_days: 6)
      pecs = Skrong::Models::Target.create("Pectorals", decay_threshold_days: 5)

      # Create movements in different categories
      upper_push = Skrong::Models::Category.all.find { |c| c.name == "Upper Push" }.not_nil!
      lower_squat = Skrong::Models::Category.all.find { |c| c.name == "Lower Squat" }.not_nil!

      bench = Skrong::Models::Movement.create("Bench Press", upper_push.id)
      bench.add_target(pecs.id)

      squat = Skrong::Models::Movement.create("Squat", lower_squat.id)
      squat.add_target(quads.id)

      output = IO::Memory.new
      Skrong::Commands::Export.export_movements("/tmp/test_export_movements.md", output: output)

      content = File.read("/tmp/test_export_movements.md")
      content.should contain("# UPPER PUSH")
      content.should contain("# LOWER SQUAT")

      File.delete("/tmp/test_export_movements.md")
    end

    it "shows export summary" do
      category = Skrong::Models::Category.all.first
      Skrong::Models::Movement.create("Test Movement", category.id)

      output = IO::Memory.new
      Skrong::Commands::Export.export_movements("/tmp/test_export_movements.md", output: output)

      output_str = output.to_s
      output_str.should contain("Exporting")
      output_str.should contain("exported successfully")

      File.delete("/tmp/test_export_movements.md")
    end

    it "handles empty movements list" do
      output = IO::Memory.new
      Skrong::Commands::Export.export_movements("/tmp/test_export_movements.md", output: output)

      output_str = output.to_s
      output_str.should contain("No movements to export")
    end

    it "handles movements with no targets" do
      category = Skrong::Models::Category.all.first
      Skrong::Models::Movement.create("Movement Without Targets", category.id)

      output = IO::Memory.new
      Skrong::Commands::Export.export_movements("/tmp/test_export_movements.md", output: output)

      File.exists?("/tmp/test_export_movements.md").should be_true

      content = File.read("/tmp/test_export_movements.md")
      content.should contain("- name: \"Movement Without Targets\"")
      content.should contain("  category:")

      File.delete("/tmp/test_export_movements.md")
    end
  end
end
