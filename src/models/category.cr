module Skrong
  module Models
    class Category
      property id : Int64
      property name : String
      property display_order : Int32

      def initialize(@id : Int64, @name : String, @display_order : Int32)
      end

      # Returns all categories ordered by display_order
      def self.all : Array(Category)
        categories = [] of Category
        db = DB::Connection.instance

        db.query("SELECT id, name, display_order FROM categories ORDER BY display_order") do |rs|
          rs.each do
            categories << Category.new(
              id: rs.read(Int64),
              name: rs.read(String),
              display_order: rs.read(Int32)
            )
          end
        end

        categories
      end

      # Finds a category by ID
      def self.find(id : Int64) : Category?
        db = DB::Connection.instance

        db.query_one?(
          "SELECT id, name, display_order FROM categories WHERE id = ?",
          id,
          as: {Int64, String, Int32}
        ).try do |row|
          Category.new(id: row[0], name: row[1], display_order: row[2])
        end
      end

      # Creates a new category
      def self.create(name : String, display_order : Int32) : Category
        db = DB::Connection.instance

        db.exec("INSERT INTO categories (name, display_order) VALUES (?, ?)", name, display_order)

        # Get the last inserted ID
        id = db.query_one("SELECT last_insert_rowid()", as: Int64)

        Category.new(id: id, name: name, display_order: display_order)
      end

      # String representation returns the category name
      def to_s : String
        @name
      end
    end
  end
end
