require "../spec_helper"

describe Skrong::Commands::Summary do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".run" do
    it "shows message when no workouts on the date" do
      output = IO::Memory.new
      Skrong::Commands::Summary.run(date: Time.local(2026, 3, 24), output: output)

      output.to_s.should contain("No workouts")
      output.to_s.should contain("2026-03-24")
    end

    it "shows summary for a specific date" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))

      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 8)

      output = IO::Memory.new
      Skrong::Commands::Summary.run(date: Time.local(2026, 3, 24), output: output)

      output_str = output.to_s
      output_str.should contain("2026-03-24")
      output_str.should contain("Bench Press")
      output_str.should contain("185.0")
    end

    it "groups sets by movement" do
      category = Skrong::Models::Category.all.first
      bench = Skrong::Models::Movement.create("Bench Press", category.id)
      squat = Skrong::Models::Movement.create("Squat", category.id)
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))

      Skrong::Models::Set.create(session.id, bench.id, 185.0, 8, 7)
      Skrong::Models::Set.create(session.id, bench.id, 185.0, 8, 8)
      Skrong::Models::Set.create(session.id, squat.id, 225.0, 5, 9)

      output = IO::Memory.new
      Skrong::Commands::Summary.run(date: Time.local(2026, 3, 24), output: output)

      output_str = output.to_s
      output_str.should contain("Bench Press")
      output_str.should contain("Squat")
    end

    it "shows total volume per movement" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))

      # 185 x 8 = 1480, do 3 sets = 4440 total
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 8)
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 8)

      output = IO::Memory.new
      Skrong::Commands::Summary.run(date: Time.local(2026, 3, 24), output: output)

      output.to_s.should contain("4440")
    end

    it "shows set count per movement" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))

      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 8)
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 8)

      output = IO::Memory.new
      Skrong::Commands::Summary.run(date: Time.local(2026, 3, 24), output: output)

      output.to_s.should contain("3 sets")
    end

    it "shows targets that were worked" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      target = Skrong::Models::Target.create("Chest")
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)

      output = IO::Memory.new
      Skrong::Commands::Summary.run(date: Time.local(2026, 3, 24), output: output)

      output.to_s.should contain("Chest")
    end

    it "shows aggregate statistics" do
      category = Skrong::Models::Category.all.first
      bench = Skrong::Models::Movement.create("Bench Press", category.id)
      squat = Skrong::Models::Movement.create("Squat", category.id)
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))

      Skrong::Models::Set.create(session.id, bench.id, 185.0, 8, 7)
      Skrong::Models::Set.create(session.id, squat.id, 225.0, 5, 9)

      output = IO::Memory.new
      Skrong::Commands::Summary.run(date: Time.local(2026, 3, 24), output: output)

      output_str = output.to_s
      # Should show total sets and movements
      output_str.should contain("Total movements: 2")
      output_str.should contain("Total sets/efforts: 2")
    end

    it "defaults to today if no date provided" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      today = Time.local(2026, 3, 24)
      session = Skrong::Models::Session.create(today)

      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)

      output = IO::Memory.new
      Skrong::Commands::Summary.run(output: output, today: today)

      output.to_s.should contain("2026-03-24")
    end

    it "shows individual set details" do
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))

      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 8)

      output = IO::Memory.new
      Skrong::Commands::Summary.run(date: Time.local(2026, 3, 24), output: output)

      output_str = output.to_s
      output_str.should contain("185.0 x 8")
      output_str.should contain("RPE 7")
      output_str.should contain("RPE 8")
    end
  end
end
