module Skrong
  module DB
    module Migrations
      def self.run
        db = Connection.instance

        # Create schema_version table if it doesn't exist
        create_schema_version_table(db)

        # Run initial schema creation
        create_categories_table(db)
        create_targets_table(db)
        create_movements_table(db)
        create_movement_targets_table(db)
        create_sessions_table(db)
        create_sets_table(db)

        seed_categories(db)

        # Apply any pending migrations
        apply_migrations(db)
      end

      private def self.create_schema_version_table(db)
        db.exec <<-SQL
          CREATE TABLE IF NOT EXISTS schema_version (
            version INTEGER PRIMARY KEY,
            applied_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        SQL
      end

      private def self.get_current_version(db) : Int32
        begin
          db.query_one("SELECT MAX(version) FROM schema_version", as: Int32?)
        rescue
          0
        end || 0
      end

      private def self.set_version(db, version : Int32)
        db.exec("INSERT INTO schema_version (version) VALUES (?)", version)
      end

      private def self.apply_migrations(db)
        current_version = get_current_version(db)

        # Migration 1: Add endurance support (activity_type, nullable fields, distance/duration)
        if current_version < 1
          migrate_to_v1(db)
          set_version(db, 1)
        end
      end

      # Migration 1: Add support for endurance activities
      private def self.migrate_to_v1(db)
        # Check if activity_type column exists in categories
        has_activity_type = false
        db.query("PRAGMA table_info(categories)") do |rs|
          rs.each do
            rs.read(Int64)    # cid
            name = rs.read(String)
            has_activity_type = true if name == "activity_type"
            rs.read(String)   # type
            rs.read(Int64)    # notnull
            rs.read           # dflt_value
            rs.read(Int64)    # pk
          end
        end

        unless has_activity_type
          # Add activity_type to categories
          db.exec("ALTER TABLE categories ADD COLUMN activity_type TEXT DEFAULT 'strength'")
        end

        # Check if we need to migrate sets table
        has_distance = false
        db.query("PRAGMA table_info(sets)") do |rs|
          rs.each do
            rs.read(Int64)    # cid
            name = rs.read(String)
            has_distance = true if name == "distance"
            rs.read(String)   # type
            rs.read(Int64)    # notnull
            rs.read           # dflt_value
            rs.read(Int64)    # pk
          end
        end

        unless has_distance
          # SQLite doesn't support making existing columns nullable or adding multiple columns atomically
          # So we need to recreate the sets table
          db.exec <<-SQL
            -- Create new sets table with updated schema
            CREATE TABLE sets_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              session_id INTEGER NOT NULL,
              movement_id INTEGER NOT NULL,
              weight REAL,
              reps INTEGER,
              rpe INTEGER NOT NULL,
              distance REAL,
              duration_seconds INTEGER,
              FOREIGN KEY (session_id) REFERENCES sessions(id),
              FOREIGN KEY (movement_id) REFERENCES movements(id)
            )
          SQL

          # Copy existing data
          db.exec <<-SQL
            INSERT INTO sets_new (id, session_id, movement_id, weight, reps, rpe)
            SELECT id, session_id, movement_id, weight, reps, rpe FROM sets
          SQL

          # Drop old table and rename new one
          db.exec("DROP TABLE sets")
          db.exec("ALTER TABLE sets_new RENAME TO sets")
        end
      end

      private def self.create_categories_table(db)
        db.exec <<-SQL
          CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            display_order INTEGER DEFAULT 0,
            activity_type TEXT DEFAULT 'strength'
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
            weight REAL,
            reps INTEGER,
            rpe INTEGER NOT NULL,
            distance REAL,
            duration_seconds INTEGER,
            FOREIGN KEY (session_id) REFERENCES sessions(id),
            FOREIGN KEY (movement_id) REFERENCES movements(id)
          )
        SQL
      end

      private def self.seed_categories(db)
        # Check if categories already exist
        count = db.query_one("SELECT COUNT(*) FROM categories", as: Int32)
        return if count > 0

        # Seed the 6 default categories (all strength type)
        categories = [
          "Upper Push",
          "Upper Pull",
          "Lower Hinge",
          "Lower Squat",
          "Armor & Isolation",
          "Core & Stability"
        ]

        categories.each_with_index do |name, index|
          db.exec("INSERT INTO categories (name, display_order, activity_type) VALUES (?, ?, ?)", name, index + 1, "strength")
        end
      end
    end
  end
end
