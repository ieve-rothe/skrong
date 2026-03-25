require "sqlite3"

module Skrong
  module DB
    module Connection
      @@instance : ::DB::Database?

      # Returns the singleton database connection
      def self.instance : ::DB::Database
        @@instance ||= begin
          ensure_db_directory
          ::DB.open("sqlite3://#{db_path}")
        end
      end

      # Returns the XDG-compliant database file path
      def self.db_path : String
        data_home = ENV["XDG_DATA_HOME"]? || Path.home.join(".local", "share").to_s
        File.join(data_home, "skrong", "skrong.db")
      end

      # Resets the connection (primarily for testing)
      def self.reset!
        @@instance.try(&.close)
        @@instance = nil
      end

      # Ensures the database directory exists
      private def self.ensure_db_directory
        db_dir = File.dirname(db_path)
        Dir.mkdir_p(db_dir) unless Dir.exists?(db_dir)
      end
    end
  end
end
