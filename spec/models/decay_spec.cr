require "../spec_helper"

describe Skrong::Models::Decay do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".calculate_for_target" do
    it "returns nil when target has no qualifying sets" do
      target = Skrong::Models::Target.create("Quadriceps")
      today = Time.local(2026, 3, 24)

      result = Skrong::Models::Decay.calculate_for_target(target, today: today)

      result.should be_nil
    end

    it "calculates days since last hit" do
      target = Skrong::Models::Target.create("Quadriceps")
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)
      movement.add_target(target.id)

      # Create a session 4 days ago
      session = Skrong::Models::Session.create(Time.local(2026, 3, 20))
      Skrong::Models::Set.create(session.id, movement.id, 225.0, 5, 8)

      today = Time.local(2026, 3, 24)
      result = Skrong::Models::Decay.calculate_for_target(target, today: today)

      result.should_not be_nil
      result.not_nil![:days_since].should eq(4)
    end

    it "counts all sets regardless of RPE" do
      target = Skrong::Models::Target.create("Quadriceps")
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)
      movement.add_target(target.id)

      # Create low RPE set today
      session1 = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      Skrong::Models::Set.create(session1.id, movement.id, 135.0, 10, 3)

      # Create higher RPE set 4 days ago
      session2 = Skrong::Models::Session.create(Time.local(2026, 3, 20))
      Skrong::Models::Set.create(session2.id, movement.id, 225.0, 5, 8)

      today = Time.local(2026, 3, 24)
      result = Skrong::Models::Decay.calculate_for_target(target, today: today)

      result.should_not be_nil
      result.not_nil![:days_since].should eq(0)  # Should use the RPE 3 set from today
    end

    it "determines OK status when within threshold" do
      target = Skrong::Models::Target.create("Quadriceps", decay_threshold_days: 5)
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 3, 20))
      Skrong::Models::Set.create(session.id, movement.id, 225.0, 5, 8)

      today = Time.local(2026, 3, 24)  # 4 days later
      result = Skrong::Models::Decay.calculate_for_target(target, today: today)

      result.not_nil![:status].should eq(:ok)
    end

    it "determines WARN status when days_since is threshold + 1 or + 2" do
      target = Skrong::Models::Target.create("Hamstrings", decay_threshold_days: 5)
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("RDL", category.id)
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 3, 18))
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)

      today = Time.local(2026, 3, 24)  # 6 days later (threshold is 5)
      result = Skrong::Models::Decay.calculate_for_target(target, today: today)

      result.not_nil![:status].should eq(:warn)
    end

    it "determines CRIT status when days_since > threshold + 2" do
      target = Skrong::Models::Target.create("Lats", decay_threshold_days: 5)
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Pull-ups", category.id)
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 2, 20))
      Skrong::Models::Set.create(session.id, movement.id, 0.0, 10, 7)

      today = Time.local(2026, 3, 24)  # 32 days later
      result = Skrong::Models::Decay.calculate_for_target(target, today: today)

      result.not_nil![:status].should eq(:crit)
    end

    it "includes last hit date" do
      target = Skrong::Models::Target.create("Chest")
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 3, 20))
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)

      today = Time.local(2026, 3, 24)
      result = Skrong::Models::Decay.calculate_for_target(target, today: today)

      result.not_nil![:last_hit_date].should eq(Time.local(2026, 3, 20))
    end

    it "includes last movement name" do
      target = Skrong::Models::Target.create("Chest")
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)
      movement.add_target(target.id)

      session = Skrong::Models::Session.create(Time.local(2026, 3, 20))
      Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)

      today = Time.local(2026, 3, 24)
      result = Skrong::Models::Decay.calculate_for_target(target, today: today)

      result.not_nil![:last_movement_name].should eq("Bench Press")
    end

    it "uses most recent qualifying set across multiple movements" do
      target = Skrong::Models::Target.create("Quadriceps")
      category = Skrong::Models::Category.all.first
      squat = Skrong::Models::Movement.create("Squat", category.id)
      leg_press = Skrong::Models::Movement.create("Leg Press", category.id)

      squat.add_target(target.id)
      leg_press.add_target(target.id)

      # Older squat
      session1 = Skrong::Models::Session.create(Time.local(2026, 3, 15))
      Skrong::Models::Set.create(session1.id, squat.id, 225.0, 5, 8)

      # More recent leg press
      session2 = Skrong::Models::Session.create(Time.local(2026, 3, 22))
      Skrong::Models::Set.create(session2.id, leg_press.id, 300.0, 10, 7)

      today = Time.local(2026, 3, 24)
      result = Skrong::Models::Decay.calculate_for_target(target, today: today)

      result.not_nil![:days_since].should eq(2)
      result.not_nil![:last_movement_name].should eq("Leg Press")
    end
  end

  describe ".calculate_all" do
    it "calculates decay for all tracked targets" do
      target1 = Skrong::Models::Target.create("Quadriceps", is_tracked: true)
      target2 = Skrong::Models::Target.create("Hamstrings", is_tracked: true)
      target3 = Skrong::Models::Target.create("Calves", is_tracked: false)

      results = Skrong::Models::Decay.calculate_all(today: Time.local(2026, 3, 24))

      # Should only include tracked targets
      results.size.should eq(2)
    end

    it "returns results sorted by status priority (CRIT, WARN, OK)" do
      category = Skrong::Models::Category.all.first

      ok_target = Skrong::Models::Target.create("OK Target", decay_threshold_days: 10)
      warn_target = Skrong::Models::Target.create("WARN Target", decay_threshold_days: 5)
      crit_target = Skrong::Models::Target.create("CRIT Target", decay_threshold_days: 5)

      ok_movement = Skrong::Models::Movement.create("OK Movement", category.id)
      warn_movement = Skrong::Models::Movement.create("WARN Movement", category.id)
      crit_movement = Skrong::Models::Movement.create("CRIT Movement", category.id)

      ok_movement.add_target(ok_target.id)
      warn_movement.add_target(warn_target.id)
      crit_movement.add_target(crit_target.id)

      today = Time.local(2026, 3, 24)

      # OK: 2 days ago (within threshold of 10)
      session1 = Skrong::Models::Session.create(Time.local(2026, 3, 22))
      Skrong::Models::Set.create(session1.id, ok_movement.id, 100.0, 10, 5)

      # WARN: 6 days ago (threshold 5, so 6 = warn)
      session2 = Skrong::Models::Session.create(Time.local(2026, 3, 18))
      Skrong::Models::Set.create(session2.id, warn_movement.id, 100.0, 10, 5)

      # CRIT: 20 days ago (threshold 5, so 20 = crit)
      session3 = Skrong::Models::Session.create(Time.local(2026, 3, 4))
      Skrong::Models::Set.create(session3.id, crit_movement.id, 100.0, 10, 5)

      results = Skrong::Models::Decay.calculate_all(today: today)

      results[0][:target].name.should eq("CRIT Target")
      results[1][:target].name.should eq("WARN Target")
      results[2][:target].name.should eq("OK Target")
    end
  end
end
