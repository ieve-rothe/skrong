require "../spec_helper"

describe Skrong::Commands::Log do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run

    # Add a test movement for logging
    category = Skrong::Models::Category.all.first
    Skrong::Models::Movement.create("Bench Press", category.id)
  end

  describe ".run" do
    it "logs a set for today's date" do
      # Simulate user input: today, category 1, movement 1, payload, done
      input = IO::Memory.new("y\n1\n1\n185 8 7\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      # Verify session was created
      sessions = Skrong::Models::Session.all
      sessions.size.should eq(1)
      sessions.first.date.should eq(Time.local(2026, 3, 24))

      # Verify set was created
      sets = Skrong::Models::Set.all
      sets.size.should eq(1)
      sets.first.weight.should eq(185.0)
      sets.first.reps.should eq(8)
      sets.first.rpe.should eq(7)
    end

    it "logs a set for a custom date" do
      input = IO::Memory.new("n\n2026-03-20\n1\n1\n225 5 8\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      sessions = Skrong::Models::Session.all
      sessions.first.date.should eq(Time.local(2026, 3, 20))
    end

    it "handles invalid date and re-prompts" do
      # First try invalid date, then valid date
      input = IO::Memory.new("n\ninvalid-date\n2026-03-20\n1\n1\n185 8 7\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      sessions = Skrong::Models::Session.all
      sessions.first.date.should eq(Time.local(2026, 3, 20))

      output.to_s.should contain("Invalid")
    end

    it "handles invalid payload and re-prompts" do
      # Invalid payload first, then valid
      input = IO::Memory.new("y\n1\n1\ninvalid\n185 8 7\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      sets = Skrong::Models::Set.all
      sets.size.should eq(1)
      sets.first.weight.should eq(185.0)

      output.to_s.should contain("Invalid")
    end

    it "logs multiple sets with sticky loop (y option)" do
      # Log 3 sets of the same movement
      input = IO::Memory.new("y\n1\n1\n185 8 7\ny\n185 8 8\ny\n185 8 9\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      sets = Skrong::Models::Set.all
      sets.size.should eq(3)
      sets[0].rpe.should eq(7)
      sets[1].rpe.should eq(8)
      sets[2].rpe.should eq(9)
    end

    pending "changes movement with sticky loop (c option)" do
      # Create a second movement
      category = Skrong::Models::Category.all[1]  # Upper Pull
      second_movement = Skrong::Models::Movement.create("Pull-ups", category.id)

      # Log first movement, then change to second
      input = IO::Memory.new("y\n1\n1\n185 8 7\nc\n2\n1\n0 10 8\nn\n")

      # Use File to avoid IO::Memory capacity issues
      output = File.open("/dev/null", "w")

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      output.close

      sets = Skrong::Models::Set.all
      sets.size.should eq(2)

      # First set should be from Upper Push (category 1)
      first_movement = Skrong::Models::Movement.find(sets[0].movement_id)
      first_movement.not_nil!.category_id.should eq(1)

      # Second set should be from the pull-ups
      sets[1].movement_id.should eq(second_movement.id)
    end

    it "uses default values when Enter is pressed on repeat" do
      # Log a set, then press Enter to repeat with same values
      input = IO::Memory.new("y\n1\n1\n185 8 7\ny\n\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      sets = Skrong::Models::Set.all
      sets.size.should eq(2)
      sets[0].weight.should eq(185.0)
      sets[0].reps.should eq(8)
      sets[0].rpe.should eq(7)
      sets[1].weight.should eq(185.0)  # Same as previous
      sets[1].reps.should eq(8)
      sets[1].rpe.should eq(7)
    end

    it "displays session summary on completion" do
      input = IO::Memory.new("y\n1\n1\n185 8 7\ny\n185 8 8\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      output_str = output.to_s
      output_str.should contain("Session logged")
      output_str.should contain("2026-03-24")
      output_str.should contain("2 sets")
    end

    it "displays category selection menu" do
      input = IO::Memory.new("y\n1\n1\n185 8 7\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      output_str = output.to_s
      output_str.should contain("Select category")
      output_str.should contain("Upper Push")
      output_str.should contain("Upper Pull")
    end

    it "displays movement selection menu filtered by category" do
      input = IO::Memory.new("y\n1\n1\n185 8 7\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      output_str = output.to_s
      output_str.should contain("Movements:")
      output_str.should contain("Bench Press")
    end

    it "creates all sets in the same session" do
      input = IO::Memory.new("y\n1\n1\n185 8 7\ny\n185 8 8\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      sessions = Skrong::Models::Session.all
      sessions.size.should eq(1)

      sets = Skrong::Models::Set.find_by_session(sessions.first.id)
      sets.size.should eq(2)
    end

    it "quits gracefully with 'q' at category selection after logging sets" do
      input = IO::Memory.new("y\n1\n1\n185 8 7\nc\nq\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      # Verify set was created
      sets = Skrong::Models::Set.all
      sets.size.should eq(1)

      # Verify summary was shown
      output_str = output.to_s
      output_str.should contain("Session logged")
      output_str.should contain("1 sets")
    end

    it "quits gracefully with 'q' at category selection without logging sets" do
      input = IO::Memory.new("y\nq\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      # Verify no sets were created
      sets = Skrong::Models::Set.all
      sets.size.should eq(0)

      # Verify cancellation message was shown
      output_str = output.to_s
      output_str.should contain("No sets logged")
      output_str.should contain("cancelled")
    end

    it "quits gracefully with 'q' at movement selection" do
      input = IO::Memory.new("y\n1\nq\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      # Verify no sets were created
      sets = Skrong::Models::Set.all
      sets.size.should eq(0)

      output_str = output.to_s
      output_str.should contain("No sets logged")
    end

    it "quits gracefully with 'q' at payload entry" do
      input = IO::Memory.new("y\n1\n1\nq\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      # Verify no sets were created
      sets = Skrong::Models::Set.all
      sets.size.should eq(0)

      output_str = output.to_s
      output_str.should contain("No sets logged")
    end

    it "quits gracefully with 'q' at continue prompt" do
      input = IO::Memory.new("y\n1\n1\n185 8 7\nq\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      # Verify set was created
      sets = Skrong::Models::Set.all
      sets.size.should eq(1)

      # Verify summary was shown (q acts like n/done)
      output_str = output.to_s
      output_str.should contain("Session logged")
    end

    it "goes back from movement selection to category selection" do
      input = IO::Memory.new("y\n1\nb\n2\n1\n135 8 7\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      # Verify set was created
      sets = Skrong::Models::Set.all
      sets.size.should eq(1)

      output_str = output.to_s
      output_str.should contain("Session logged")
    end

    it "goes back from payload entry to movement selection" do
      # Create a second movement in the same category
      category = Skrong::Models::Category.all.first
      Skrong::Models::Movement.create("Dumbbell Press", category.id)

      input = IO::Memory.new("y\n1\n1\nb\n2\n185 8 7\nn\n")
      output = IO::Memory.new

      Skrong::Commands::Log.run(
        input: input,
        output: output,
        today: Time.local(2026, 3, 24)
      )

      # Verify set was created for the second movement
      sets = Skrong::Models::Set.all
      sets.size.should eq(1)

      movement = Skrong::Models::Movement.find(sets.first.movement_id)
      movement.not_nil!.name.should eq("Dumbbell Press")
    end
  end
end
