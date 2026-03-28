module Skrong
  module Models
    class Set
      property id : Int64
      property session_id : Int64
      property movement_id : Int64
      property weight : Float64?
      property reps : Int32?
      property rpe : Int32
      property distance : Float64?
      property duration_seconds : Int32?

      def initialize(@id : Int64, @session_id : Int64, @movement_id : Int64,
                     @weight : Float64?, @reps : Int32?, @rpe : Int32,
                     @distance : Float64? = nil, @duration_seconds : Int32? = nil)
      end

      # Returns all sets
      def self.all : Array(Set)
        sets = [] of Set
        db = DB::Connection.instance

        db.query("SELECT id, session_id, movement_id, weight, reps, rpe, distance, duration_seconds FROM sets") do |rs|
          rs.each do
            sets << Set.new(
              id: rs.read(Int64),
              session_id: rs.read(Int64),
              movement_id: rs.read(Int64),
              weight: rs.read(Float64?),
              reps: rs.read(Int32?),
              rpe: rs.read(Int32),
              distance: rs.read(Float64?),
              duration_seconds: rs.read(Int32?)
            )
          end
        end

        sets
      end

      # Finds a set by ID
      def self.find(id : Int64) : Set?
        db = DB::Connection.instance

        db.query_one?(
          "SELECT id, session_id, movement_id, weight, reps, rpe, distance, duration_seconds FROM sets WHERE id = ?",
          id,
          as: {Int64, Int64, Int64, Float64?, Int32?, Int32, Float64?, Int32?}
        ).try do |row|
          Set.new(
            id: row[0],
            session_id: row[1],
            movement_id: row[2],
            weight: row[3],
            reps: row[4],
            rpe: row[5],
            distance: row[6],
            duration_seconds: row[7]
          )
        end
      end

      # Creates a new strength set
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

      # Creates a new endurance set
      def self.create_endurance(session_id : Int64, movement_id : Int64, distance : Float64, duration_seconds : Int32, rpe : Int32) : Set
        db = DB::Connection.instance

        db.exec(
          "INSERT INTO sets (session_id, movement_id, distance, duration_seconds, rpe) VALUES (?, ?, ?, ?, ?)",
          session_id,
          movement_id,
          distance,
          duration_seconds,
          rpe
        )

        # Get the last inserted ID
        id = db.query_one("SELECT last_insert_rowid()", as: Int64)

        Set.new(
          id: id,
          session_id: session_id,
          movement_id: movement_id,
          weight: nil,
          reps: nil,
          rpe: rpe,
          distance: distance,
          duration_seconds: duration_seconds
        )
      end

      # Finds all sets for a session
      def self.find_by_session(session_id : Int64) : Array(Set)
        sets = [] of Set
        db = DB::Connection.instance

        db.query(
          "SELECT id, session_id, movement_id, weight, reps, rpe, distance, duration_seconds FROM sets WHERE session_id = ?",
          session_id
        ) do |rs|
          rs.each do
            sets << Set.new(
              id: rs.read(Int64),
              session_id: rs.read(Int64),
              movement_id: rs.read(Int64),
              weight: rs.read(Float64?),
              reps: rs.read(Int32?),
              rpe: rs.read(Int32),
              distance: rs.read(Float64?),
              duration_seconds: rs.read(Int32?)
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
          "SELECT id, session_id, movement_id, weight, reps, rpe, distance, duration_seconds FROM sets WHERE movement_id = ?",
          movement_id
        ) do |rs|
          rs.each do
            sets << Set.new(
              id: rs.read(Int64),
              session_id: rs.read(Int64),
              movement_id: rs.read(Int64),
              weight: rs.read(Float64?),
              reps: rs.read(Int32?),
              rpe: rs.read(Int32),
              distance: rs.read(Float64?),
              duration_seconds: rs.read(Int32?)
            )
          end
        end

        sets
      end

      # Helper to check if this is a strength set
      def strength_set? : Bool
        !@weight.nil? && !@reps.nil?
      end

      # Helper to check if this is an endurance set
      def endurance_set? : Bool
        !@distance.nil? && !@duration_seconds.nil?
      end

      # Format duration as HH:MM:SS or MM:SS
      def format_duration(seconds : Int32) : String
        hours = seconds // 3600
        minutes = (seconds % 3600) // 60
        secs = seconds % 60

        if hours > 0
          "#{hours}:#{"#{minutes}".rjust(2, '0')}:#{"#{secs}".rjust(2, '0')}"
        else
          "#{minutes}:#{"#{secs}".rjust(2, '0')}"
        end
      end

      # Calculate pace per mile (MM:SS format)
      def calculate_pace(distance : Float64, seconds : Int32) : String
        return "N/A" if distance <= 0
        pace_seconds = (seconds / distance).to_i
        minutes = pace_seconds // 60
        secs = pace_seconds % 60
        "#{minutes}:#{"#{secs}".rjust(2, '0')}/mi"
      end

      # String representation of the set
      def to_s : String
        if strength_set?
          "#{@weight} x #{@reps} @ RPE #{@rpe}"
        elsif endurance_set?
          dist = @distance.not_nil!
          dur = @duration_seconds.not_nil!
          "#{dist} mi in #{format_duration(dur)} @ RPE #{@rpe} (Pace: #{calculate_pace(dist, dur)})"
        else
          "Invalid set"
        end
      end
    end
  end
end
