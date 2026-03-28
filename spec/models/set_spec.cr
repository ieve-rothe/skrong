require "../spec_helper"

describe Skrong::Models::Set do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".all" do
    it "returns an empty array when no sets exist" do
      sets = Skrong::Models::Set.all
      sets.should be_empty
    end

    it "returns all sets" do
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)

      Skrong::Models::Set.create(session.id, movement.id, 225.0, 5, 8)
      Skrong::Models::Set.create(session.id, movement.id, 225.0, 5, 9)

      sets = Skrong::Models::Set.all
      sets.size.should eq(2)
    end
  end

  describe ".find" do
    it "finds a set by id" do
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)

      created = Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)

      found = Skrong::Models::Set.find(created.id)

      found.should_not be_nil
      found.not_nil!.weight.should eq(185.0)
      found.not_nil!.reps.should eq(8)
      found.not_nil!.rpe.should eq(7)
    end

    it "returns nil for non-existent id" do
      set = Skrong::Models::Set.find(9999_i64)
      set.should be_nil
    end
  end

  describe ".create" do
    it "creates a set with all attributes" do
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Deadlift", category.id)

      set = Skrong::Models::Set.create(session.id, movement.id, 315.0, 3, 10)

      set.id.should be > 0
      set.session_id.should eq(session.id)
      set.movement_id.should eq(movement.id)
      set.weight.should eq(315.0)
      set.reps.should eq(3)
      set.rpe.should eq(10)
    end
  end

  describe ".find_by_session" do
    it "finds all sets for a session" do
      session1 = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      session2 = Skrong::Models::Session.create(Time.local(2026, 3, 25))
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Squat", category.id)

      Skrong::Models::Set.create(session1.id, movement.id, 225.0, 5, 8)
      Skrong::Models::Set.create(session1.id, movement.id, 225.0, 5, 9)
      Skrong::Models::Set.create(session2.id, movement.id, 245.0, 3, 9)

      sets = Skrong::Models::Set.find_by_session(session1.id)
      sets.size.should eq(2)
    end

    it "returns empty array when no sets exist for session" do
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      sets = Skrong::Models::Set.find_by_session(session.id)
      sets.should be_empty
    end
  end

  describe ".find_by_movement" do
    it "finds all sets for a movement" do
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      category = Skrong::Models::Category.all.first
      movement1 = Skrong::Models::Movement.create("Squat", category.id)
      movement2 = Skrong::Models::Movement.create("Deadlift", category.id)

      Skrong::Models::Set.create(session.id, movement1.id, 225.0, 5, 8)
      Skrong::Models::Set.create(session.id, movement1.id, 225.0, 5, 9)
      Skrong::Models::Set.create(session.id, movement2.id, 315.0, 3, 9)

      sets = Skrong::Models::Set.find_by_movement(movement1.id)
      sets.size.should eq(2)
    end
  end

  describe "#to_s" do
    it "returns formatted set description" do
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      category = Skrong::Models::Category.all.first
      movement = Skrong::Models::Movement.create("Bench Press", category.id)

      set = Skrong::Models::Set.create(session.id, movement.id, 185.0, 8, 7)

      set.to_s.should eq("185.0 x 8 @ RPE 7")
    end
  end
end
