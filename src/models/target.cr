module Skrong
  module Models
    class Target
      property id : Int64
      property name : String
      property is_tracked : Bool
      property decay_threshold_days : Int32

      def initialize(@id : Int64, @name : String, @is_tracked : Bool, @decay_threshold_days : Int32)
      end

      # Returns all targets
      def self.all : Array(Target)
        targets = [] of Target
        db = DB::Connection.instance

        db.query("SELECT id, name, is_tracked, decay_threshold_days FROM targets") do |rs|
          rs.each do
            targets << Target.new(
              id: rs.read(Int64),
              name: rs.read(String),
              is_tracked: rs.read(Int32) == 1,
              decay_threshold_days: rs.read(Int32)
            )
          end
        end

        targets
      end

      # Returns only tracked targets
      def self.tracked : Array(Target)
        targets = [] of Target
        db = DB::Connection.instance

        db.query("SELECT id, name, is_tracked, decay_threshold_days FROM targets WHERE is_tracked = 1") do |rs|
          rs.each do
            targets << Target.new(
              id: rs.read(Int64),
              name: rs.read(String),
              is_tracked: rs.read(Int32) == 1,
              decay_threshold_days: rs.read(Int32)
            )
          end
        end

        targets
      end

      # Finds a target by ID
      def self.find(id : Int64) : Target?
        db = DB::Connection.instance

        db.query_one?(
          "SELECT id, name, is_tracked, decay_threshold_days FROM targets WHERE id = ?",
          id,
          as: {Int64, String, Int32, Int32}
        ).try do |row|
          Target.new(
            id: row[0],
            name: row[1],
            is_tracked: row[2] == 1,
            decay_threshold_days: row[3]
          )
        end
      end

      # Creates a new target with optional parameters
      def self.create(name : String, is_tracked : Bool = true, decay_threshold_days : Int32 = 5) : Target
        db = DB::Connection.instance

        is_tracked_int = is_tracked ? 1 : 0

        db.exec(
          "INSERT INTO targets (name, is_tracked, decay_threshold_days) VALUES (?, ?, ?)",
          name,
          is_tracked_int,
          decay_threshold_days
        )

        # Get the last inserted ID
        id = db.query_one("SELECT last_insert_rowid()", as: Int64)

        Target.new(
          id: id,
          name: name,
          is_tracked: is_tracked,
          decay_threshold_days: decay_threshold_days
        )
      end

      # Updates target attributes
      def update(name : String? = nil, is_tracked : Bool? = nil, decay_threshold_days : Int32? = nil)
        db = DB::Connection.instance

        # Update instance variables
        @name = name unless name.nil?
        @is_tracked = is_tracked unless is_tracked.nil?
        @decay_threshold_days = decay_threshold_days unless decay_threshold_days.nil?

        # Update database
        is_tracked_int = @is_tracked ? 1 : 0

        db.exec(
          "UPDATE targets SET name = ?, is_tracked = ?, decay_threshold_days = ? WHERE id = ?",
          @name,
          is_tracked_int,
          @decay_threshold_days,
          @id
        )
      end

      # String representation returns the target name
      def to_s : String
        @name
      end
    end
  end
end
