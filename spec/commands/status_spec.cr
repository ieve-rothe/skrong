require "../spec_helper"

describe Skrong::Commands::Status do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".run" do
    it "shows message when no targets are tracked" do
      output = IO::Memory.new
      Skrong::Commands::Status.run(output: output)

      output.to_s.should contain("No tracked targets found")
    end

    it "displays targets with their decay status" do
      category = Skrong::Models::Category.all.first
      target = Skrong::Models::Target.create("Quadriceps", decay_threshold_days: 10)
      movement = Skrong::Models::Movement.create("Squat", category.id)
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 3, 20))
      Skrong::Models::Set.create(session.id, movement.id, 225.0, 5, 8)

      output = IO::Memory.new
      Skrong::Commands::Status.run(output: output, today: Time.local(2026, 3, 24))

      output_str = output.to_s
      output_str.should contain("Quadriceps")
      output_str.should contain("4")  # days ago
      output_str.should contain("[OK]")
      output_str.should contain("Squat")
    end

    it "shows WARN status for targets approaching threshold" do
      category = Skrong::Models::Category.all.first
      target = Skrong::Models::Target.create("Hamstrings", decay_threshold_days: 4)
      movement = Skrong::Models::Movement.create("RDL", category.id)
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 3, 18))
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)

      output = IO::Memory.new
      Skrong::Commands::Status.run(output: output, today: Time.local(2026, 3, 24))

      output_str = output.to_s
      output_str.should contain("Hamstrings")
      output_str.should contain("[WARN]")
    end

    it "shows CRIT status for neglected targets" do
      category = Skrong::Models::Category.all.first
      target = Skrong::Models::Target.create("Lats", decay_threshold_days: 5)
      movement = Skrong::Models::Movement.create("Pull-ups", category.id)
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 2, 20))
      Skrong::Models::Set.create(session.id, movement.id, 0.0, 10, 7)

      output = IO::Memory.new
      Skrong::Commands::Status.run(output: output, today: Time.local(2026, 3, 24))

      output_str = output.to_s
      output_str.should contain("Lats")
      output_str.should contain("[CRIT]")
    end

    it "shows -- for targets that have never been hit" do
      Skrong::Models::Target.create("Never Hit Target")

      output = IO::Memory.new
      Skrong::Commands::Status.run(output: output)

      output_str = output.to_s
      output_str.should contain("Never Hit Target")
      output_str.should contain("--")
      output_str.should contain("[CRIT]")
    end

    it "formats dates as MMM DD" do
      category = Skrong::Models::Category.all.first
      target = Skrong::Models::Target.create("Chest")
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 3, 20))
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)

      output = IO::Memory.new
      Skrong::Commands::Status.run(output: output, today: Time.local(2026, 3, 24))

      output_str = output.to_s
      output_str.should contain("Mar 20")
    end

    it "includes the table header and separators" do
      output = IO::Memory.new
      Skrong::Commands::Status.run(output: output)

      output_str = output.to_s
      output_str.should contain("SYSTEM STATUS")
      output_str.should contain("TARGET MUSCLE GROUPS")
      output_str.should contain("=")
      output_str.should contain("-")
    end

    it "sorts results by status priority (CRIT first)" do
      category = Skrong::Models::Category.all.first

      ok_target = Skrong::Models::Target.create("OK Target", decay_threshold_days: 10)
      crit_target = Skrong::Models::Target.create("CRIT Target", decay_threshold_days: 5)

      ok_movement = Skrong::Models::Movement.create("OK Movement", category.id)
      crit_movement = Skrong::Models::Movement.create("CRIT Movement", category.id)

      ok_movement.add_target(ok_target.id)
      crit_movement.add_target(crit_target.id)

      session1 = Skrong::Models::Session.create(Time.local(2026, 3, 22))
      Skrong::Models::Set.create(session1.id, ok_movement.id, 100.0, 10, 5)

      session2 = Skrong::Models::Session.create(Time.local(2026, 2, 20))
      Skrong::Models::Set.create(session2.id, crit_movement.id, 100.0, 10, 5)

      output = IO::Memory.new
      Skrong::Commands::Status.run(output: output, today: Time.local(2026, 3, 24))

      output_str = output.to_s
      lines = output_str.lines

      # Find the data lines
      crit_line_index = lines.index { |l| l.includes?("CRIT Target") }
      ok_line_index = lines.index { |l| l.includes?("OK Target") }

      crit_line_index.should_not be_nil
      ok_line_index.should_not be_nil
      crit_line_index.not_nil!.should be < ok_line_index.not_nil!
    end
  end
end
