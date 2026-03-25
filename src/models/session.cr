module Skrong
  module Models
    class Session
      property id : Int64
      property date : Time
      property notes : String?

      def initialize(@id : Int64, @date : Time, @notes : String? = nil)
      end

      # Returns all sessions
      def self.all : Array(Session)
        sessions = [] of Session
        db = DB::Connection.instance

        db.query("SELECT id, date, notes FROM sessions") do |rs|
          rs.each do
            sessions << Session.new(
              id: rs.read(Int64),
              date: Time.parse(rs.read(String), "%Y-%m-%d", Time::Location.local),
              notes: rs.read(String?)
            )
          end
        end

        sessions
      end

      # Finds a session by ID
      def self.find(id : Int64) : Session?
        db = DB::Connection.instance

        db.query_one?(
          "SELECT id, date, notes FROM sessions WHERE id = ?",
          id,
          as: {Int64, String, String?}
        ).try do |row|
          Session.new(
            id: row[0],
            date: Time.parse(row[1], "%Y-%m-%d", Time::Location.local),
            notes: row[2]
          )
        end
      end

      # Creates a new session
      def self.create(date : Time, notes : String? = nil) : Session
        db = DB::Connection.instance

        # Store only the date part (YYYY-MM-DD)
        date_string = date.to_s("%Y-%m-%d")

        db.exec("INSERT INTO sessions (date, notes) VALUES (?, ?)", date_string, notes)

        # Get the last inserted ID
        id = db.query_one("SELECT last_insert_rowid()", as: Int64)

        Session.new(id: id, date: date, notes: notes)
      end

      # Finds sessions by date
      def self.find_by_date(date : Time) : Array(Session)
        sessions = [] of Session
        db = DB::Connection.instance

        date_string = date.to_s("%Y-%m-%d")

        db.query("SELECT id, date, notes FROM sessions WHERE date = ?", date_string) do |rs|
          rs.each do
            sessions << Session.new(
              id: rs.read(Int64),
              date: Time.parse(rs.read(String), "%Y-%m-%d", Time::Location.local),
              notes: rs.read(String?)
            )
          end
        end

        sessions
      end

      # Returns the most recent session by date
      def self.latest : Session?
        db = DB::Connection.instance

        db.query_one?(
          "SELECT id, date, notes FROM sessions ORDER BY date DESC LIMIT 1",
          as: {Int64, String, String?}
        ).try do |row|
          Session.new(
            id: row[0],
            date: Time.parse(row[1], "%Y-%m-%d", Time::Location.local),
            notes: row[2]
          )
        end
      end

      # Updates session notes
      def update_notes(notes : String)
        db = DB::Connection.instance

        @notes = notes

        db.exec("UPDATE sessions SET notes = ? WHERE id = ?", notes, @id)
      end

      # String representation returns formatted date
      def to_s : String
        @date.to_s("%Y-%m-%d")
      end
    end
  end
end
