require "../spec_helper"

describe Skrong::Models::Session do
  before_each do
    Skrong::DB::Connection.reset!
    test_db_path = Skrong::DB::Connection.db_path
    File.delete(test_db_path) if File.exists?(test_db_path)
    Skrong::DB::Migrations.run
  end

  describe ".all" do
    it "returns an empty array when no sessions exist" do
      sessions = Skrong::Models::Session.all
      sessions.should be_empty
    end

    it "returns all sessions" do
      Skrong::Models::Session.create(Time.local(2026, 3, 24))
      Skrong::Models::Session.create(Time.local(2026, 3, 25))

      sessions = Skrong::Models::Session.all
      sessions.size.should eq(2)
    end
  end

  describe ".find" do
    it "finds a session by id" do
      date = Time.local(2026, 3, 24)
      created = Skrong::Models::Session.create(date)

      found = Skrong::Models::Session.find(created.id)

      found.should_not be_nil
      found.not_nil!.date.should eq(date)
    end

    it "returns nil for non-existent id" do
      session = Skrong::Models::Session.find(9999_i64)
      session.should be_nil
    end
  end

  describe ".create" do
    it "creates a session with a date" do
      date = Time.local(2026, 3, 24)
      session = Skrong::Models::Session.create(date)

      session.id.should be > 0
      session.date.should eq(date)
      session.notes.should be_nil
    end

    it "creates a session with notes" do
      date = Time.local(2026, 3, 24)
      session = Skrong::Models::Session.create(date, notes: "Felt strong today")

      session.notes.should eq("Felt strong today")
    end

    it "stores date only (not time)" do
      date_with_time = Time.local(2026, 3, 24, 14, 30, 0)
      session = Skrong::Models::Session.create(date_with_time)

      # Date should be stored as just the date part
      session.date.year.should eq(2026)
      session.date.month.should eq(3)
      session.date.day.should eq(24)
    end
  end

  describe ".find_by_date" do
    it "finds sessions by date" do
      date1 = Time.local(2026, 3, 24)
      date2 = Time.local(2026, 3, 25)

      Skrong::Models::Session.create(date1)
      Skrong::Models::Session.create(date1)
      Skrong::Models::Session.create(date2)

      sessions = Skrong::Models::Session.find_by_date(date1)
      sessions.size.should eq(2)
    end

    it "returns empty array when no sessions exist for date" do
      date = Time.local(2026, 3, 24)
      sessions = Skrong::Models::Session.find_by_date(date)
      sessions.should be_empty
    end
  end

  describe ".latest" do
    it "returns the most recent session by date" do
      Skrong::Models::Session.create(Time.local(2026, 3, 20))
      Skrong::Models::Session.create(Time.local(2026, 3, 25))
      Skrong::Models::Session.create(Time.local(2026, 3, 22))

      latest = Skrong::Models::Session.latest

      latest.should_not be_nil
      latest.not_nil!.date.should eq(Time.local(2026, 3, 25))
    end

    it "returns nil when no sessions exist" do
      Skrong::Models::Session.latest.should be_nil
    end
  end

  describe "#update_notes" do
    it "updates session notes" do
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))

      session.update_notes("Hip feeling squishy")

      updated = Skrong::Models::Session.find(session.id).not_nil!
      updated.notes.should eq("Hip feeling squishy")
    end
  end

  describe "#to_s" do
    it "returns formatted date string" do
      session = Skrong::Models::Session.create(Time.local(2026, 3, 24))
      session.to_s.should eq("2026-03-24")
    end
  end
end
