# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Skrong** is a CLI workout tracker focused on muscle group recovery and decay tracking. It's built in Crystal with SQLite, using a test-driven development approach (252 specs). The philosophy is recovery-first: track when each muscle group was last worked and flag those needing attention.

## Essential Commands

```bash
# Install dependencies
shards install

# Build binary
crystal build src/skrong.cr -o bin/skrong

# Run all tests
crystal spec

# Run specific test file
crystal spec spec/commands/log_spec.cr

# Run specific test (by line number)
crystal spec spec/commands/log_spec.cr:15

# Initialize database for testing
./bin/skrong init
```

## Architecture Overview

### Core Philosophy
- **Decay Tracking**: Each muscle group has a `decay_threshold_days` that triggers warnings
- **Status System**: OK (green) / WARN (yellow) / CRIT (red) based on days since last workout
- **All Sets Count**: Any set, regardless of RPE, counts as "hitting" a muscle group

### Database Design (SQLite)

**Key tables:**
- `targets` - Muscle groups with decay thresholds and tracking flags
- `categories` - 6 default movement categories (Upper Push/Pull, Lower Hinge/Squat, Armor & Isolation, Core & Stability)
- `movements` - Exercises linked to categories
- `movement_targets` - Junction table (many-to-many: movements ↔ targets)
- `sessions` - Workout sessions with dates (can be backdated)
- `sets` - Individual sets with weight, reps, RPE

**Critical business rule:** All sets count toward decay calculation, regardless of RPE.

### Code Structure

```
src/
├── skrong.cr              # Entry point, imports all modules
├── cli.cr                 # Command routing and argument parsing
├── db/
│   ├── connection.cr      # Singleton DB connection (XDG-compliant path)
│   └── migrations.cr      # Schema creation + category seeding
├── models/                # CRUD operations for each table
│   ├── category.cr
│   ├── target.cr
│   ├── movement.cr
│   ├── session.cr
│   ├── set.cr
│   └── decay.cr           # Decay calculation engine
├── ui/
│   ├── colors.cr          # ANSI color utilities
│   ├── prompt.cr          # Input parsing/validation (includes payload parser)
│   ├── select.cr          # Interactive number selection
│   └── table.cr           # Status report rendering
└── commands/              # Each command is a separate module
    ├── init.cr            # Database initialization
    ├── status.cr          # Decay status report
    ├── log.cr             # Interactive workout logging (5 phases)
    ├── summary.cr         # Workout summaries by date
    ├── library.cr         # Movement management (list/add/delete)
    ├── targets.cr         # Target management (list/add/edit/delete)
    └── seed.cr            # Bulk import from seed files
```

### Command Flow - `skrong log`

The `log` command has a **5-phase interactive flow**:

1. **Date Selection**: Confirm today or enter custom date (YYYY-MM-DD)
2. **Category Selection**: Pick from 6 categories
3. **Movement Selection**: Filtered by selected category
4. **Payload Entry**: Space-delimited input `weight reps rpe` (e.g., `185 8 7`)
5. **Sticky Loop**:
   - `(r)epeat` - Log another set for same movement
   - `(c)hange` - Select new movement
   - `(d)one` - Finish session

**State management**: Tracks `last_weight`, `last_reps`, `last_rpe` within session for fast re-entry.

### Payload Parsing

Space-delimited format: `[weight] [reps] [rpe]`

**Parser location:** `src/ui/prompt.cr`

**Validation:**
- Weight: Float > 0
- Reps: Int32 > 0
- RPE: Int32 between 1-10

**Error handling:** Show format example and re-prompt on parse failure.

### Seed File System

**Commands:**
- `skrong seed targets <file>` - Bulk import muscle groups
- `skrong seed movements <file>` - Bulk import exercises

**Format (YAML-like):**

Targets:
```yaml
- name: "Quadriceps"
  decay_threshold_days: 6
```

Movements:
```yaml
- name: "Barbell Bench Press"
  category: "Upper Push"
  targets:
    - "Pectorals"
    - "Triceps"
```

**Parser features:**
- Strips parenthetical notes: `"Pectorals" (Chest)` → `"Pectorals"`
- Ignores comment lines starting with `#`
- Skips existing entries (idempotent)
- All imported targets default to `is_tracked: true`

**Files:** `targets_seed.md`, `movements_seed.md`

## TDD Workflow

This project follows strict test-driven development:

1. **Write specs first** in `spec/` directory mirroring `src/` structure
2. **Run specs to see failure** (red)
3. **Implement feature** to pass specs (green)
4. **Refactor** if needed
5. **All specs must pass** before committing (252 examples, 1 pending)

### Test Patterns

**Before each block:** Reset database connection and delete test DB
```crystal
before_each do
  Skrong::DB::Connection.reset!
  test_db_path = Skrong::DB::Connection.db_path
  File.delete(test_db_path) if File.exists?(test_db_path)
  Skrong::DB::Migrations.run
end
```

**IO testing:** Use `IO::Memory` for input/output capture
```crystal
input = IO::Memory.new("test input\n")
output = IO::Memory.new
Skrong::Commands::Status.run(output: output)
output.to_s.should contain("expected text")
```

## Key Implementation Details

### Database Path (XDG Compliance)
Location: `~/.local/share/skrong/skrong.db` (respects `$XDG_DATA_HOME`)

**Critical fix:** Use `Path.home.join(".local", "share").to_s` NOT `File.expand_path("~/.local/share")` which creates literal `~` directory.

### Singleton Pattern for DB Connection
`src/db/connection.cr` uses `@@instance` class variable. Always access via `DB::Connection.instance`.

### Date Handling
- Sessions store dates as TEXT in `YYYY-MM-DD` format (not timestamps)
- Parser in `UI::Prompt.parse_date()` catches both `Time::Format::Error` and `ArgumentError`
- Log command defaults to today when user just hits Enter (changed from requiring `y`)

### Bool vs Int32 Confusion
Models use `Bool` for `is_tracked` field, but database stores as `INTEGER` (0/1). Conversions:
- Reading: `rs.read(Int32) == 1` converts to Bool
- Writing: `is_tracked ? 1 : 0` converts to Int32

**Common bug:** Comparing Bool to integer (use `target.is_tracked` not `target.is_tracked == 1`)

### Movement Category Association
Movements have `category_id` foreign key + many-to-many targets via `movement_targets` junction table.

The 6 default categories are **seeded on init** and should not be modified.

## Common Gotchas

1. **Date format**: Sessions use date strings, not timestamps
2. **Duplicate prevention**: Seed import checks existing names before inserting
3. **Test database**: Specs create/delete test DB before each test
4. **Bool serialization**: Database uses INT, models use Bool (conversion needed)

## File Conventions

- **Models**: One file per table, named after singular table name
- **Commands**: One file per command, module-based (no classes)
- **Specs**: Mirror `src/` structure in `spec/`, suffix with `_spec.cr`
- **Seed files**: Markdown extension (`.md`) for YAML-like format

## Development Workflow

1. Run specs after any change: `crystal spec`
2. Build binary after source changes: `crystal build src/skrong.cr -o bin/skrong`
3. Test manually with: `./bin/skrong <command>`
4. Re-initialize DB when testing: `./bin/skrong init`
5. Import seed data: `./bin/skrong seed targets targets_seed.md`
