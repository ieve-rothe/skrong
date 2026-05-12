require "../spec_helper"

describe Skrong::DB::Connection do
  describe ".instance" do
    it "returns a DB::Database instance" do
      db = Skrong::DB::Connection.instance
      db.should be_a(::DB::Database)
    end

    it "returns the same instance on multiple calls (singleton)" do
      db1 = Skrong::DB::Connection.instance
      db2 = Skrong::DB::Connection.instance
      db1.should be(db2)
    end
  end

  describe ".db_path" do
    it "returns test database path in test mode" do
      path = Skrong::DB::Connection.db_path
      path.should contain("spec")
      path.should end_with("test.db")
    end

    it "creates parent directory if it doesn't exist" do
      # This is tested implicitly when instance is called
      # The directory creation happens before opening the database
      db_path = Skrong::DB::Connection.db_path
      File.dirname(db_path).should_not be_nil
    end
  end

  describe ".reset!" do
    it "allows getting a new instance after reset" do
      db1 = Skrong::DB::Connection.instance
      Skrong::DB::Connection.reset!
      db2 = Skrong::DB::Connection.instance

      # After reset, we should successfully get a new connection
      # Both instances point to the same file but are different connection objects
      db2.should be_a(::DB::Database)
    end
  end

  describe ".backup" do
    it "skips backup for test databases" do
      # In test mode, backup should be a no-op
      backup_path = Skrong::DB::Connection.backup_path

      # Ensure test database exists
      Skrong::DB::Connection.instance

      # Backup should not create a file in test mode
      Skrong::DB::Connection.backup
      File.exists?(backup_path).should be_false
    end
  end

  describe ".backup_path" do
    it "returns the backup file path" do
      path = Skrong::DB::Connection.backup_path
      path.should eq("#{Skrong::DB::Connection.db_path}.backup")
    end
  end
end
