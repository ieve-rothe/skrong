module Skrong
  module Models
    class Movement
      property id : Int64
      property name : String
      property category_id : Int64

      def initialize(@id : Int64, @name : String, @category_id : Int64)
      end

      # Returns all movements
      def self.all : Array(Movement)
        movements = [] of Movement
        db = DB::Connection.instance

        db.query("SELECT id, name, category_id FROM movements") do |rs|
          rs.each do
            movements << Movement.new(
              id: rs.read(Int64),
              name: rs.read(String),
              category_id: rs.read(Int64)
            )
          end
        end

        movements
      end

      # Finds a movement by ID
      def self.find(id : Int64) : Movement?
        db = DB::Connection.instance

        db.query_one?(
          "SELECT id, name, category_id FROM movements WHERE id = ?",
          id,
          as: {Int64, String, Int64}
        ).try do |row|
          Movement.new(id: row[0], name: row[1], category_id: row[2])
        end
      end

      # Finds movements by category
      def self.find_by_category(category_id : Int64) : Array(Movement)
        movements = [] of Movement
        db = DB::Connection.instance

        db.query("SELECT id, name, category_id FROM movements WHERE category_id = ?", category_id) do |rs|
          rs.each do
            movements << Movement.new(
              id: rs.read(Int64),
              name: rs.read(String),
              category_id: rs.read(Int64)
            )
          end
        end

        movements
      end

      # Creates a new movement
      def self.create(name : String, category_id : Int64) : Movement
        db = DB::Connection.instance

        db.exec("INSERT INTO movements (name, category_id) VALUES (?, ?)", name, category_id)

        # Get the last inserted ID
        id = db.query_one("SELECT last_insert_rowid()", as: Int64)

        Movement.new(id: id, name: name, category_id: category_id)
      end

      # Adds a target to this movement via the junction table
      def add_target(target_id : Int64, is_primary : Bool = true)
        db = DB::Connection.instance

        is_primary_int = is_primary ? 1 : 0

        db.exec(
          "INSERT INTO movement_targets (movement_id, target_id, is_primary) VALUES (?, ?, ?)",
          @id,
          target_id,
          is_primary_int
        )
      end

      # Returns all targets associated with this movement
      # Returns an array of NamedTuples with target_id and is_primary flag
      def targets : Array(NamedTuple(target_id: Int64, is_primary: Bool))
        targets = [] of NamedTuple(target_id: Int64, is_primary: Bool)
        db = DB::Connection.instance

        db.query(
          "SELECT target_id, is_primary FROM movement_targets WHERE movement_id = ?",
          @id
        ) do |rs|
          rs.each do
            targets << {
              target_id: rs.read(Int64),
              is_primary: rs.read(Int32) == 1
            }
          end
        end

        targets
      end

      # Returns the associated category
      def category : Category?
        Category.find(@category_id)
      end

      # String representation returns the movement name
      def to_s : String
        @name
      end
    end
  end
end
