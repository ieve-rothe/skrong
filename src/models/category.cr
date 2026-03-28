module Skrong
  module Models
    class Category
      property id : Int64
      property name : String
      property display_order : Int32
      property activity_type : String

      def initialize(@id : Int64, @name : String, @display_order : Int32, @activity_type : String = "strength")
      end

      # Returns all categories ordered by display_order
      def self.all : Array(Category)
        categories = [] of Category
        db = DB::Connection.instance

        db.query("SELECT id, name, display_order, activity_type FROM categories ORDER BY display_order") do |rs|
          rs.each do
            categories << Category.new(
              id: rs.read(Int64),
              name: rs.read(String),
              display_order: rs.read(Int32),
              activity_type: rs.read(String)
            )
          end
        end

        categories
      end

      # Finds a category by ID
      def self.find(id : Int64) : Category?
        db = DB::Connection.instance

        db.query_one?(
          "SELECT id, name, display_order, activity_type FROM categories WHERE id = ?",
          id,
          as: {Int64, String, Int32, String}
        ).try do |row|
          Category.new(id: row[0], name: row[1], display_order: row[2], activity_type: row[3])
        end
      end

      # Creates a new category
      def self.create(name : String, display_order : Int32, activity_type : String = "strength") : Category
        db = DB::Connection.instance

        db.exec("INSERT INTO categories (name, display_order, activity_type) VALUES (?, ?, ?)", name, display_order, activity_type)

        # Get the last inserted ID
        id = db.query_one("SELECT last_insert_rowid()", as: Int64)

        Category.new(id: id, name: name, display_order: display_order, activity_type: activity_type)
      end

      # String representation returns the category name
      def to_s : String
        @name
      end
    end
  end
end
