module Skrong
  module Models
    class Set
      property id : Int64
      property session_id : Int64
      property movement_id : Int64
      property weight : Float64
      property reps : Int32
      property rpe : Int32

      def initialize(@id : Int64, @session_id : Int64, @movement_id : Int64,
                     @weight : Float64, @reps : Int32, @rpe : Int32)
      end

      # Returns all sets
      def self.all : Array(Set)
        sets = [] of Set
        db = DB::Connection.instance

        db.query("SELECT id, session_id, movement_id, weight, reps, rpe FROM sets") do |rs|
          rs.each do
            sets << Set.new(
              id: rs.read(Int64),
              session_id: rs.read(Int64),
              movement_id: rs.read(Int64),
              weight: rs.read(Float64),
              reps: rs.read(Int32),
              rpe: rs.read(Int32)
            )
          end
        end

        sets
      end

      # Finds a set by ID
      def self.find(id : Int64) : Set?
        db = DB::Connection.instance

        db.query_one?(
          "SELECT id, session_id, movement_id, weight, reps, rpe FROM sets WHERE id = ?",
          id,
          as: {Int64, Int64, Int64, Float64, Int32, Int32}
        ).try do |row|
          Set.new(
            id: row[0],
            session_id: row[1],
            movement_id: row[2],
            weight: row[3],
            reps: row[4],
            rpe: row[5]
          )
        end
      end

      # Creates a new set
      def self.create(session_id : Int64, movement_id : Int64, weight : Float64, reps : Int32, rpe : Int32) : Set
        db = DB::Connection.instance

        db.exec(
          "INSERT INTO sets (session_id, movement_id, weight, reps, rpe) VALUES (?, ?, ?, ?, ?)",
          session_id,
          movement_id,
          weight,
          reps,
          rpe
        )

        # Get the last inserted ID
        id = db.query_one("SELECT last_insert_rowid()", as: Int64)

        Set.new(
          id: id,
          session_id: session_id,
          movement_id: movement_id,
          weight: weight,
          reps: reps,
          rpe: rpe
        )
      end

      # Finds all sets for a session
      def self.find_by_session(session_id : Int64) : Array(Set)
        sets = [] of Set
        db = DB::Connection.instance

        db.query(
          "SELECT id, session_id, movement_id, weight, reps, rpe FROM sets WHERE session_id = ?",
          session_id
        ) do |rs|
          rs.each do
            sets << Set.new(
              id: rs.read(Int64),
              session_id: rs.read(Int64),
              movement_id: rs.read(Int64),
              weight: rs.read(Float64),
              reps: rs.read(Int32),
              rpe: rs.read(Int32)
            )
          end
        end

        sets
      end

      # Finds all sets for a movement
      def self.find_by_movement(movement_id : Int64) : Array(Set)
        sets = [] of Set
        db = DB::Connection.instance

        db.query(
          "SELECT id, session_id, movement_id, weight, reps, rpe FROM sets WHERE movement_id = ?",
          movement_id
        ) do |rs|
          rs.each do
            sets << Set.new(
              id: rs.read(Int64),
              session_id: rs.read(Int64),
              movement_id: rs.read(Int64),
              weight: rs.read(Float64),
              reps: rs.read(Int32),
              rpe: rs.read(Int32)
            )
          end
        end

        sets
      end

      # String representation of the set
      def to_s : String
        "#{@weight} x #{@reps} @ RPE #{@rpe}"
      end
    end
  end
end
