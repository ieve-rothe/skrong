require "./spec_helper"

describe Skrong::CLI do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
  end

  describe ".run" do
    it "shows help when no arguments provided" do
      output = IO::Memory.new
      Skrong::CLI.run([] of String, output: output)

      output.to_s.should contain("Usage")
      output.to_s.should contain("skrong")
    end

    it "shows help with --help flag" do
      output = IO::Memory.new
      Skrong::CLI.run(["--help"], output: output)

      output.to_s.should contain("Usage")
    end

    it "shows help with -h flag" do
      output = IO::Memory.new
      Skrong::CLI.run(["-h"], output: output)

      output.to_s.should contain("Usage")
    end

    it "shows version with --version flag" do
      output = IO::Memory.new
      Skrong::CLI.run(["--version"], output: output)

      output.to_s.should contain(Skrong::VERSION)
    end

    it "routes to init command" do
      output = IO::Memory.new
      Skrong::CLI.run(["init"], output: output)

      output.to_s.should contain("Database initialized")
    end

    it "routes to status command" do
      Skrong::DB::Migrations.run
      output = IO::Memory.new
      Skrong::CLI.run(["status"], output: output)

      output.to_s.should contain("SYSTEM STATUS")
    end

    it "routes to library list command" do
      Skrong::DB::Migrations.run
      output = IO::Memory.new
      Skrong::CLI.run(["library", "list"], output: output)

      output_str = output.to_s
      # Should show either the library header or the empty message
      (output_str.includes?("MOVEMENT LIBRARY") || output_str.includes?("No movements")).should be_true
    end

    it "routes to library delete command" do
      Skrong::DB::Migrations.run
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Test Movement", category.id)

      input = IO::Memory.new("y\n")
      output = IO::Memory.new
      Skrong::CLI.run(["library", "delete", movement.id.to_s], input: input, output: output)

      output.to_s.should contain("deleted")
    end

    it "shows error for unknown command" do
      output = IO::Memory.new
      Skrong::CLI.run(["unknown"], output: output)

      output.to_s.should contain("Unknown command")
    end

    it "shows error for library without subcommand" do
      output = IO::Memory.new
      Skrong::CLI.run(["library"], output: output)

      output.to_s.should contain("library list")
      output.to_s.should contain("library add")
      output.to_s.should contain("library delete")
    end

    it "shows error for library delete without ID" do
      output = IO::Memory.new
      Skrong::CLI.run(["library", "delete"], output: output)

      output.to_s.should contain("Usage")
      output.to_s.should contain("<movement_id>")
    end

    it "lists available commands in help" do
      output = IO::Memory.new
      Skrong::CLI.run([] of String, output: output)

      output_str = output.to_s
      output_str.should contain("init")
      output_str.should contain("status")
      output_str.should contain("log")
      output_str.should contain("summary")
      output_str.should contain("library")
      output_str.should contain("targets")
    end

    it "routes to summary command for today" do
      Skrong::DB::Migrations.run
      output = IO::Memory.new
      Skrong::CLI.run(["summary"], output: output)

      output.to_s.should contain("WORKOUT SUMMARY")
    end

    it "routes to summary command with date" do
      Skrong::DB::Migrations.run
      output = IO::Memory.new
      Skrong::CLI.run(["summary", "2026-03-24"], output: output)

      output.to_s.should contain("2026-03-24")
    end

    it "shows error for invalid date in summary" do
      Skrong::DB::Migrations.run
      output = IO::Memory.new
      Skrong::CLI.run(["summary", "invalid-date"], output: output)

      output.to_s.should contain("Invalid date")
    end

    it "routes to targets list command" do
      Skrong::DB::Migrations.run
      output = IO::Memory.new
      Skrong::CLI.run(["targets", "list"], output: output)

      output_str = output.to_s
      # Should show either the targets header or the empty message
      (output_str.includes?("TARGET LIBRARY") || output_str.includes?("No targets")).should be_true
    end

    it "routes to targets add command" do
      Skrong::DB::Migrations.run
      input = IO::Memory.new("Test Target\n\n\n")
      output = IO::Memory.new
      Skrong::CLI.run(["targets", "add"], input: input, output: output)

      output.to_s.should contain("Target added")
    end

    it "routes to targets edit command" do
      Skrong::DB::Migrations.run
      target = Skrong::Models::Target.create("Test")

      input = IO::Memory.new("\n\n\n")
      output = IO::Memory.new
      Skrong::CLI.run(["targets", "edit", target.id.to_s], input: input, output: output)

      output.to_s.should contain("updated")
    end

    it "routes to targets delete command" do
      Skrong::DB::Migrations.run
      target = Skrong::Models::Target.create("Test")

      input = IO::Memory.new("y\n")
      output = IO::Memory.new
      Skrong::CLI.run(["targets", "delete", target.id.to_s], input: input, output: output)

      output.to_s.should contain("deleted")
    end

    it "shows error for targets without subcommand" do
      output = IO::Memory.new
      Skrong::CLI.run(["targets"], output: output)

      output.to_s.should contain("targets list")
      output.to_s.should contain("targets add")
      output.to_s.should contain("targets edit")
      output.to_s.should contain("targets delete")
    end

    it "shows error for targets edit without ID" do
      output = IO::Memory.new
      Skrong::CLI.run(["targets", "edit"], output: output)

      output.to_s.should contain("Usage")
      output.to_s.should contain("<target_id>")
    end

    it "shows error for targets delete without ID" do
      output = IO::Memory.new
      Skrong::CLI.run(["targets", "delete"], output: output)

      output.to_s.should contain("Usage")
      output.to_s.should contain("<target_id>")
    end
  end
end
