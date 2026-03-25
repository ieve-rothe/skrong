module Skrong
  module DB
    module Migrations
      def self.run
        db = Connection.instance

        create_categories_table(db)
        create_targets_table(db)
        create_movements_table(db)
        create_movement_targets_table(db)
        create_sessions_table(db)
        create_sets_table(db)

        seed_categories(db)
      end

      private def self.create_categories_table(db)
        db.exec <<-SQL
          CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            display_order INTEGER DEFAULT 0
          )
        SQL
      end

      private def self.create_targets_table(db)
        db.exec <<-SQL
          CREATE TABLE IF NOT EXISTS targets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            is_tracked INTEGER DEFAULT 1,
            decay_threshold_days INTEGER DEFAULT 5
          )
        SQL
      end

      private def self.create_movements_table(db)
        db.exec <<-SQL
          CREATE TABLE IF NOT EXISTS movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            category_id INTEGER NOT NULL,
            FOREIGN KEY (category_id) REFERENCES categories(id)
          )
        SQL
      end

      private def self.create_movement_targets_table(db)
        db.exec <<-SQL
          CREATE TABLE IF NOT EXISTS movement_targets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            movement_id INTEGER NOT NULL,
            target_id INTEGER NOT NULL,
            is_primary INTEGER DEFAULT 1,
            FOREIGN KEY (movement_id) REFERENCES movements(id),
            FOREIGN KEY (target_id) REFERENCES targets(id)
          )
        SQL

        # Create unique index on movement_id and target_id
        db.exec <<-SQL
          CREATE UNIQUE INDEX IF NOT EXISTS idx_movement_targets_unique
          ON movement_targets(movement_id, target_id)
        SQL
      end

      private def self.create_sessions_table(db)
        db.exec <<-SQL
          CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            notes TEXT
          )
        SQL
      end

      private def self.create_sets_table(db)
        db.exec <<-SQL
          CREATE TABLE IF NOT EXISTS sets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            movement_id INTEGER NOT NULL,
            weight REAL NOT NULL,
            reps INTEGER NOT NULL,
            rpe INTEGER NOT NULL,
            FOREIGN KEY (session_id) REFERENCES sessions(id),
            FOREIGN KEY (movement_id) REFERENCES movements(id)
          )
        SQL
      end

      private def self.seed_categories(db)
        # Check if categories already exist
        count = db.query_one("SELECT COUNT(*) FROM categories", as: Int32)
        return if count > 0

        # Seed the 6 default categories
        categories = [
          "Upper Push",
          "Upper Pull",
          "Lower Hinge",
          "Lower Squat",
          "Armor & Isolation",
          "Core & Stability"
        ]

        categories.each_with_index do |name, index|
          db.exec("INSERT INTO categories (name, display_order) VALUES (?, ?)", name, index + 1)
        end
      end
    end
  end
end
