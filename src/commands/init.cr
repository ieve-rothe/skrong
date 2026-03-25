module Skrong
  module Commands
    module Init
      # Initializes the database with schema and seed data
      def self.run(output : IO = STDOUT)
        db = DB::Connection.instance

        # Check if already initialized by checking if categories exist
        category_count = db.query_one("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='categories'", as: Int32)

        if category_count > 0
          # Check if categories are already seeded
          existing_categories = db.query_one("SELECT COUNT(*) FROM categories", as: Int32)

          if existing_categories > 0
            output.puts "Database already initialized at #{DB::Connection.db_path}"
            output.puts "Categories: #{existing_categories}"
            return
          end
        end

        # Run migrations
        DB::Migrations.run

        output.puts "Database initialized successfully!"
        output.puts "Location: #{DB::Connection.db_path}"
        output.puts ""
        output.puts "Default categories created:"

        categories = Models::Category.all
        categories.each do |category|
          output.puts "  #{category.display_order}. #{category.name}"
        end

        output.puts ""
        output.puts "Run 'skrong library add' to add movements to your library."
      end
    end
  end
end
