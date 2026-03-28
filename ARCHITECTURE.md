# Skrong Architecture

## Overview
A CLI-based multi-sport workout tracking system that monitors muscle group training frequency and alerts on decay. Supports both strength training (weight/reps) and endurance activities (distance/time). Built in Crystal for fast execution and minimal friction.

## Tech Stack
- **Language**: Crystal (>= 1.19.1)
- **Database**: SQLite (embedded, via `crystal-sqlite3` shard v0.21.0)
- **CLI Framework**: Custom argument parsing and prompts
- **Testing**: Crystal's built-in spec framework (252 specs)
- **Deployment**: Compiled static binary

## Technical Requirements
- **Number-based Selection**: Simple numeric input for menu navigation
- **Dual Input Parsing**:
  - Strength: Space-delimited `weight reps rpe` format
  - Endurance: Space-delimited `distance duration rpe` format with MM:SS or HH:MM:SS duration parsing
- **Date Validation**: Accept YYYY-MM-DD format, validate against reasonable date ranges
- **Performance**: Sub-100ms response time for `status` command with 1000+ sets
- **XDG Compliance**: Database stored at `~/.local/share/skrong/` (respects `$XDG_DATA_HOME`)
- **Schema Migration**: Automatic upgrade of existing databases to support new features

## Data Model

### Tables

#### `targets`
Represents muscle groups to be monitored.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-increment |
| name | TEXT NOT NULL | e.g., "Quadriceps", "Rotator Cuff" |
| is_tracked | BOOLEAN DEFAULT 1 | Whether to show in status reports |
| decay_threshold_days | INTEGER DEFAULT 5 | Days until WARN status (CRIT = threshold + 2) |

#### `categories`
Movement categories for organizing the exercise library.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-increment |
| name | TEXT NOT NULL UNIQUE | e.g., "Upper Push", "Lower Hinge", "Run" |
| display_order | INTEGER DEFAULT 0 | Order for displaying in menus |
| activity_type | TEXT DEFAULT 'strength' | 'strength' or 'endurance' - determines input format |

**Default Strength Categories** (auto-seeded):
1. Upper Push
2. Upper Pull
3. Lower Hinge
4. Lower Squat
5. Armor & Isolation
6. Core & Stability

**Endurance Categories** (optional import via seed):
7. Swim
8. Bike
9. Run

#### `movements`
Exercise library with mappings to targets.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-increment |
| name | TEXT NOT NULL UNIQUE | e.g., "Seated DB Overhead Press" |
| category_id | INTEGER NOT NULL | Foreign key to categories |

#### `movement_targets`
Junction table for movement-target relationships.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-increment |
| movement_id | INTEGER NOT NULL | Foreign key to movements |
| target_id | INTEGER NOT NULL | Foreign key to targets |
| is_primary | BOOLEAN DEFAULT 1 | True for primary targets, false for secondary |

**Index**: `movement_id, target_id` (composite unique)

#### `sessions`
Workout session metadata.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-increment |
| date | DATE NOT NULL | Session date (can be backdated, format: YYYY-MM-DD) |
| created_at | DATETIME DEFAULT CURRENT_TIMESTAMP | When record was created |
| notes | TEXT NULL | Optional session notes |

#### `sets`
Individual set/effort performance data. Supports both strength and endurance activities.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-increment |
| session_id | INTEGER NOT NULL | Foreign key to sessions |
| movement_id | INTEGER NOT NULL | Foreign key to movements |
| weight | REAL NULL | Weight in lbs (for strength sets) |
| reps | INTEGER NULL | Repetitions completed (for strength sets) |
| rpe | INTEGER NOT NULL | Rate of Perceived Exertion (1-10) |
| distance | REAL NULL | Distance in miles (for endurance efforts) |
| duration_seconds | INTEGER NULL | Duration in seconds (for endurance efforts) |

**Constraints**:
- Strength sets require: `weight` AND `reps`
- Endurance efforts require: `distance` AND `duration_seconds`
- All sets/efforts require: `rpe`

#### `schema_version`
Tracks applied database migrations.

| Column | Type | Description |
|--------|------|-------------|
| version | INTEGER PRIMARY KEY | Migration version number |
| applied_at | TEXT DEFAULT CURRENT_TIMESTAMP | When migration was applied |

## CLI Commands

### `skrong status`
**Primary dashboard**. Shows all tracked targets with decay status.

**Output Format**:
```
SYSTEM STATUS: TARGET MUSCLE GROUPS
=======================================================================
TARGET                 LAST HIT      DAYS AGO    STATUS    LAST MOVEMENT
-----------------------------------------------------------------------
Glute Complex          Mar 20        4           [OK]      Heel Drives
Quadriceps             Mar 18        6           [WARN]    Dog Walk
Lats & Teres Major     Feb 28       24           [CRIT]    --
```

**Color Coding**:
- `[OK]` = 0 to decay_threshold_days (Green)
- `[WARN]` = decay_threshold_days + 1 to decay_threshold_days + 2 (Yellow)
- `[CRIT]` = > decay_threshold_days + 2 (Red)

### `skrong log`
**Interactive logging flow** for entering workout data. Automatically adapts to strength or endurance based on category selection.

**Flow**:

**Phase 1: Session Initialization**
```
$ skrong log
Log for today (2026-03-24)? (Y/n):
```
- If `y` or Enter (default): Session date = today
- If `n`: Prompt for date in YYYY-MM-DD format (validates format, allows backdating)

**Phase 2: Category Selection**
```
Select category:
  1. Upper Push
  2. Upper Pull
  3. Lower Hinge
  4. Lower Squat
  5. Armor & Isolation
  6. Core & Stability
  7. Swim (if imported)
  8. Bike (if imported)
  9. Run (if imported)

Enter number:
```
- User types category number and presses Enter
- Filters movements by selected category
- **Determines activity type** from category (strength vs endurance)

**Phase 3: Movement Selection**
```
[Category Name] Movements:
  1. Bench Press
  2. Overhead Press
  3. Dips
  ...

Enter number:
```
- Display filtered movements for selected category
- User types movement number and presses Enter

**Phase 4: Payload Entry (Fast Entry) - Dynamic Prompts**

**For Strength Activities**:
```
[Movement Name]
Enter: weight reps rpe (e.g., 185 8 7):
```
- Space-delimited input: `[weight] [reps] [rpe]`
- Example: `185 8 7` → weight=185.0, reps=8, rpe=7
- Validates: weight > 0, reps > 0, rpe 1-10
- Confirmation: `Set logged: 185.0 x 8 @ RPE 7`

**For Endurance Activities**:
```
[Movement Name]
Enter: distance duration rpe (e.g., 3.1 24:30 7):
```
- Space-delimited input: `[distance] [duration] [rpe]`
- Example: `3.1 24:30 7` → distance=3.1 mi, duration=1470 seconds, rpe=7
- Duration formats: `MM:SS` or `HH:MM:SS`
- Validates: distance > 0, duration valid format, rpe 1-10
- Confirmation: `Effort logged: 3.1 mi in 24:30 @ RPE 7`

**Phase 5: Sticky Loop**
```
Log another set of [Movement Name]?
  (r) Repeat movement
  (c) Change movement
  (d) Done with workout
```
- **`r` (Repeat)**: Shows previous values, user can hit Enter to repeat or type new values
  - Strength: `Previous: 185 8 7`
  - Endurance: `Previous: 3.1 24:30 7`
- **`c` (Change)**: Return to Phase 2 (Category Selection) - enables brick workouts (swim → bike → run)
- **`d` (Done)**: Exit logging, show session summary

**Session Summary** (after exit):
```
Session logged for [date]:
  - [N] sets/efforts across [M] movements
  - [X] muscle groups targeted
```

### `skrong library`
**Movement management interface**.

**Subcommands**:
- `skrong library list` - Show all movements grouped by category with their targets
- `skrong library add` - Add new movement (interactive prompts for name, category, targets)
- `skrong library delete <movement_id>` - Remove movement (with confirmation)

### `skrong targets`
**Target (muscle group) management interface**.

**Subcommands**:
- `skrong targets list` - Show all targets with tracking status and decay thresholds
- `skrong targets add` - Add new target (interactive prompts for name, tracked status, decay threshold)
- `skrong targets edit <target_id>` - Edit existing target (can update name, tracked status, decay threshold)
- `skrong targets delete <target_id>` - Remove target (with confirmation)

**Output Format (list)**:
```
TARGET LIBRARY
================================================================================
ID   Name                           Tracked    Decay Days
--------------------------------------------------------------------------------
1    Quadriceps                     Yes        6
2    Hamstrings                     Yes        6
3    Rotator Cuff                   Yes        3
```

### `skrong summary [date]`
**View workout summary for a specific date**. Automatically formats output based on activity type.

**Usage**:
- `skrong summary` - Show today's workout summary
- `skrong summary 2026-03-24` - Show summary for specific date

**Output Format - Strength Only**:
```
WORKOUT SUMMARY - 2026-03-24
======================================================================
Barbell Bench Press
  Set 1: 185.0 x 8 @ RPE 7
  Set 2: 185.0 x 8 @ RPE 8
  → 2 sets, 1480 total volume

SUMMARY:
  Total movements: 2
  Total sets/efforts: 2
  Total weight lifted: 1480 lbs
  Targets worked: Pectorals, Triceps, Anterior Deltoids
```

**Output Format - Endurance Only**:
```
WORKOUT SUMMARY - 2026-03-24
======================================================================
Zone 2 Run
  Effort 1: 5.0 mi in 40:00 @ RPE 6 (Pace: 8:00/mi)
  Effort 2: 3.1 mi in 24:30 @ RPE 7 (Pace: 7:54/mi)
  → 2 efforts

SUMMARY:
  Total movements: 1
  Total sets/efforts: 2
  Total distance: 8.1 mi
  Total time: 1:04:30
  Targets worked: Aerobic Base, Quadriceps, Hamstrings, Calves & Soleus
```

**Output Format - Mixed Session (Brick Workout)**:
```
WORKOUT SUMMARY - 2026-03-24
======================================================================
Barbell Bench Press
  Set 1: 185.0 x 8 @ RPE 7
  → 1 sets, 1480 total volume

Zone 2 Run
  Effort 1: 5.0 mi in 40:00 @ RPE 6 (Pace: 8:00/mi)
  → 1 efforts

SUMMARY:
  Total movements: 2
  Total sets/efforts: 2
  Total weight lifted: 1480 lbs
  Total distance: 5.0 mi
  Total time: 40:00
  Targets worked: Aerobic Base, Pectorals, Quadriceps, Triceps
```

### `skrong seed`
**Bulk import categories, targets, and movements from seed files**.

**Subcommands**:
- `skrong seed categories <file>` - Import categories (e.g., Swim, Bike, Run)
- `skrong seed targets <file>` - Import muscle groups from YAML-like seed file
- `skrong seed movements <file>` - Import exercises from YAML-like seed file

**Categories Seed Format** (`endurance_categories_seed.md`):
```yaml
# Section Header (comment)
- name: "Swim"
  activity_type: "endurance"
- name: "Bike"
  activity_type: "endurance"
- name: "Run"
  activity_type: "endurance"
```

**Targets Seed Format** (`targets_seed.md`):
```yaml
# Section Header (comment)
- name: "Quadriceps"
  decay_threshold_days: 6
- name: "Cardiovascular System"
  decay_threshold_days: 3
```

**Movements Seed Format** (`movements_seed.md`):
```yaml
# Section Header
- name: "Barbell Bench Press"
  category: "Upper Push"
  targets:
    - "Pectorals"
    - "Triceps"
    - "Anterior Deltoids"

- name: "Zone 2 Run"
  category: "Run"
  targets:
    - "Aerobic Base"
    - "Quadriceps"
    - "Hamstrings"
```

**Features**:
- Idempotent - re-running skips existing entries
- Strips parenthetical notes: `"Pectorals" (Chest)` → `"Pectorals"`
- Ignores comment lines starting with `#`
- All imported targets default to `is_tracked: true`
- Shows import summary with counts of imported/skipped/errors

### `skrong init`
**Database initialization and migration**. Creates SQLite database and tables on first run. On subsequent runs, applies any pending schema migrations while preserving existing data.

**Features**:
- Creates all necessary tables on first run
- Seeds default 6 strength categories
- Applies schema migrations for existing databases (e.g., adding endurance support)
- Idempotent - safe to run multiple times
- Automatic backup recommended before running migrations

## Business Logic Rules

### Payload Parsing

**Strength Format**: `[weight] [reps] [rpe]`

**Examples**:
- `40 15 8` → weight=40.0, reps=15, rpe=8
- `135.5 5 9` → weight=135.5, reps=5, rpe=9
- `225 3 10` → weight=225.0, reps=3, rpe=10

**Validation**:
- Weight: decimal allowed, must be > 0
- Reps: integer only, must be > 0
- RPE: integer only, must be 1-10

**Endurance Format**: `[distance] [duration] [rpe]`

**Examples**:
- `3.1 24:30 7` → distance=3.1 mi, duration=1470 seconds, rpe=7
- `5 40:00 6` → distance=5.0 mi, duration=2400 seconds, rpe=6
- `13.1 1:45:00 8` → distance=13.1 mi, duration=6300 seconds, rpe=8

**Validation**:
- Distance: decimal allowed, must be > 0 (miles)
- Duration: MM:SS or HH:MM:SS format (e.g., `24:30` or `1:24:30`)
- RPE: integer only, must be 1-10

**Error handling**: If parsing fails, show appropriate format example (strength or endurance) and re-prompt.

### Sticky Loop Defaults
When user selects "r" to repeat the same movement:

**Strength**:
1. Show previous values: `Previous: 40 15 8`
2. Prompt: `Enter (↵ to repeat, or new values):`
3. If Enter with no input → use previous values
4. If new payload → parse and use new values

**Endurance**:
1. Show previous values: `Previous: 3.1 24:30 7`
2. Prompt: `Enter (↵ to repeat, or new values):`
3. If Enter with no input → use previous values
4. If new payload → parse and use new values

**State Management**:
- Strength: Track `last_weight`, `last_reps`, `last_rpe` within session
- Endurance: Track `last_distance`, `last_duration_seconds`, `last_rpe` within session
- State cleared when changing movements or switching activity types

### Activity Type Detection
The log command automatically determines input format based on the selected category's `activity_type`:
- `activity_type == "strength"` → Prompt for `weight reps rpe`
- `activity_type == "endurance"` → Prompt for `distance duration rpe`

This allows seamless switching between strength and endurance within a single session (brick workouts).

### Set Type Determination
Sets/efforts are identified by which fields are populated:
- **Strength set**: `weight` AND `reps` are not null
- **Endurance effort**: `distance` AND `duration_seconds` are not null

### Target Weighting (V1)
**Primary and secondary targets are treated equally.** Both reset the "Last Hit" timer. Future versions may implement differential weighting.

### Decay Calculation
For each target:
1. Find most recent session date where target was hit (any RPE counts)
2. Calculate `days_since = (TODAY - last_hit_date)` in days
3. Determine status:
   - `days_since <= decay_threshold_days` → OK
   - `days_since <= decay_threshold_days + 2` → WARN
   - `days_since > decay_threshold_days + 2` → CRIT
4. If no sets exist: CRIT with "Last Hit" as "--"

## Schema Migrations

### Migration System
Skrong uses a versioned migration system to safely update existing databases:

**Migration Table**: `schema_version`
- Tracks which migrations have been applied
- Each migration has a unique version number
- Applied migrations are never re-run

**Migration Process**:
1. On `skrong init`, check current schema version
2. Apply any pending migrations in sequence
3. Record each successful migration in `schema_version` table
4. Preserve all existing data during schema updates

**Migration 1 - Endurance Support** (v1):
- Add `activity_type` column to `categories` table (default: 'strength')
- Recreate `sets` table with nullable `weight`/`reps` and new `distance`/`duration_seconds` columns
- Migrate existing set data to new schema (all existing sets remain as strength sets)
- Backward compatible: Existing strength training workflows unchanged

### Adding New Migrations
Future migrations should:
1. Check if changes already applied (idempotent)
2. Preserve existing data
3. Increment version number
4. Add to `apply_migrations()` method in `src/db/migrations.cr`

## File Structure
```
src/
├── skrong.cr              # Main entry point, CLI routing
├── cli.cr                 # Command routing and argument parsing
├── commands/
│   ├── init.cr            # Database initialization
│   ├── status.cr          # Status report generator
│   ├── log.cr             # Interactive logging flow
│   ├── summary.cr         # Workout summary by date
│   ├── library.cr         # Movement CRUD operations
│   ├── targets.cr         # Target CRUD operations
│   └── seed.cr            # Bulk import from seed files
├── models/
│   ├── category.cr        # Category model & queries
│   ├── target.cr          # Target model & queries (with name update support)
│   ├── movement.cr        # Movement model & queries
│   ├── session.cr         # Session model & queries
│   ├── set.cr             # Set model & queries
│   └── decay.cr           # Decay calculation engine
├── db/
│   ├── connection.cr      # SQLite connection handler (XDG-compliant path)
│   └── migrations.cr      # Schema creation logic
└── ui/
    ├── prompt.cr          # Input prompt helpers (text, date, payload parsing)
    ├── select.cr          # Interactive selection (number input only)
    ├── table.cr           # Status table renderer
    └── colors.cr          # Terminal color utilities
```

**UI Component Notes**:
- `select.cr` handles number-based selection with validation
- All commands accept `input` and `output` IO parameters for testing

**Testing**:
- Comprehensive test suite: 252 specs, 1 pending
- Tests mirror source structure in `spec/` directory
- All commands tested with `IO::Memory` for input/output capture
- Database reset before each test
- Test-driven development approach (red-green-refactor)

## Database Location
`~/.local/share/skrong/skrong.db` (follows XDG Base Directory spec)

**Implementation Note**: Uses `Path.home.join(".local", "share")` to properly expand home directory. Previous implementation using `File.expand_path("~/.local/share")` created a literal `~` directory.

## Code Patterns and Conventions

### Singleton Database Connection
All database access goes through `DB::Connection.instance`. Tests call `DB::Connection.reset!` before each test.

### Command Structure
Commands are modules (not classes) with a `self.run()` method that accepts `input : IO` and `output : IO` parameters:
```crystal
module Skrong::Commands::Status
  def self.run(output : IO = STDOUT)
    # Implementation
  end
end
```

### Model CRUD Pattern
Models follow consistent CRUD patterns:
- `.all` - Returns all records
- `.find(id)` - Returns single record or nil
- `.create(...)` - Creates and returns new record
- `#update(...)` - Updates existing record (instance method)

### Bool/Int Conversion
Database stores bools as INTEGER (0/1), models use Bool type:
```crystal
# Reading from DB
is_tracked: rs.read(Int32) == 1

# Writing to DB
is_tracked_int = is_tracked ? 1 : 0
```

### Input Validation with Retry
Interactive prompts use loops for validation with retry:
```crystal
loop do
  output.print "Enter value: "
  input_str = input.gets.try(&.strip) || ""

  if valid?(input_str)
    return parse(input_str)
  else
    output.puts "Invalid input. Try again."
  end
end
```

## Implementation Phases

### Phase 1: Core Data Layer ✅
1. Database connection and schema creation (including `categories` table)
2. Model classes with basic CRUD (Category, Target, Movement, Session, Set)
3. `skrong init` command
4. Seed default categories (6 macro categories)

### Phase 2: Basic UI Components ✅
1. Text input prompts (`ui/prompt.cr`)
2. Date input validation (YYYY-MM-DD format)
3. Payload parser (space-delimited: `weight reps rpe`)
4. Color output utilities

### Phase 3: Interactive Selection ✅
1. Number-based selection component (`ui/select.cr`)
2. List rendering with numbering
3. Validation and retry loops

### Phase 4: Logging Flow ✅
1. `skrong log` session initialization (date prompt with default to today)
2. Category selection menu
3. Movement selection (filtered by category)
4. Payload entry and set creation
5. Sticky loop with repeat/change/done options
6. Session summary output

### Phase 5: Reporting Engine ✅
1. Decay calculation query (using `sessions.date`)
2. Decay model with status determination logic
3. Status table rendering
4. Terminal color output (OK/WARN/CRIT)
5. `skrong status` command

### Phase 6: Movement Management ✅
1. `skrong library list` - grouped by category with targets
2. `skrong library add` - with category and target selection
3. `skrong library delete` - with confirmation

### Phase 7: Target Management ✅
1. `skrong targets list` - all targets with tracking status and decay thresholds
2. `skrong targets add` - interactive target creation
3. `skrong targets edit` - update name, tracking status, and decay threshold
4. `skrong targets delete` - with confirmation

### Phase 8: Workout Summaries ✅
1. `skrong summary` command with optional date parameter
2. Group sets by movement
3. Calculate total volume per movement
4. Show targets worked and aggregate statistics
5. Defaults to today if no date provided

### Phase 9: Bulk Import System ✅
1. YAML-like seed file parser for targets
2. YAML-like seed file parser for movements
3. `skrong seed targets` command
4. `skrong seed movements` command
5. Idempotent imports (skip existing entries)
6. Validation and error handling
7. Import summary reporting

### Phase 10: Multi-Sport Endurance Tracking ✅
1. **Schema Migration System**:
   - `schema_version` table for tracking migrations
   - Migration 1: Add endurance support to existing databases
   - Automatic migration on `skrong init`
   - Zero data loss for existing workouts

2. **Database Schema Updates**:
   - Add `activity_type` column to `categories` (default: 'strength')
   - Make `weight` and `reps` nullable in `sets`
   - Add `distance` and `duration_seconds` columns to `sets`

3. **Dual Payload Parsing**:
   - Endurance parser: `distance duration rpe`
   - Duration format support: MM:SS and HH:MM:SS
   - Unified `parse_set_payload()` with activity type branching

4. **Dynamic Log Command**:
   - Auto-detect activity type from selected category
   - Context-aware prompts (strength vs endurance format)
   - Separate state tracking for strength and endurance defaults
   - Support for brick workouts (mixed activities in one session)

5. **Enhanced Set Model**:
   - `strength_set?()` and `endurance_set?()` type detection
   - `format_duration()` - Convert seconds to HH:MM:SS
   - `calculate_pace()` - Calculate pace per mile
   - Conditional `to_s()` formatting
   - New `create_endurance()` method

6. **Smart Summary Reporting**:
   - Conditional formatting based on set type
   - Strength: "185.0 x 8 @ RPE 7"
   - Endurance: "3.1 mi in 24:30 @ RPE 7 (Pace: 7:54/mi)"
   - Separate aggregation: Total weight + Total distance/time

7. **Seed Data for Endurance**:
   - `endurance_categories_seed.md` - Swim, Bike, Run
   - `endurance_targets_seed.md` - 4 cardio targets
   - `endurance_movements_seed.md` - 12 pre-configured movements
   - `skrong seed categories` command for category import

8. **Backward Compatibility**:
   - All existing strength training workflows unchanged
   - Automatic migration preserves all data
   - Default to strength type for new categories
   - Existing test suite passes (252+ specs)

## Seed Data

### Strength Categories (Auto-seeded)
The 6 strength categories are automatically seeded on `skrong init`:
1. Upper Push
2. Upper Pull
3. Lower Hinge
4. Lower Squat
5. Armor & Isolation
6. Core & Stability

### Endurance Categories (Optional Import)
**File**: `endurance_categories_seed.md` (3 endurance sports)

Import with: `skrong seed categories endurance_categories_seed.md`

**Categories**:
7. Swim (activity_type: 'endurance')
8. Bike (activity_type: 'endurance')
9. Run (activity_type: 'endurance')

### Strength Targets (Import via seed file)
**File**: `targets_seed.md` (19 muscle groups organized by recovery time)

Import with: `skrong seed targets targets_seed.md`

**Groups**:
- **Drive Train (6 days)**: Quadriceps, Hamstrings, Gluteus Maximus
- **Lower Armor (4 days)**: Glute Medius & Minimus, Psoas & Hip Flexors, Calves & Soleus, Anterior Tibialis
- **Core (3-5 days)**: Deep Core & Transversus, Obliques, Spinal Erectors
- **Upper Engine (5 days)**: Pectorals, Lats & Teres Major, Trapezius & Rhomboids, Anterior Deltoids
- **Upper Armor (3-4 days)**: Side & Rear Deltoids, Rotator Cuff, Triceps, Biceps, Forearms & Grip

### Endurance Targets (Optional Import)
**File**: `endurance_targets_seed.md` (4 cardiovascular systems)

Import with: `skrong seed targets endurance_targets_seed.md`

**Targets**:
- **Cardiovascular System (3 days)**: General aerobic capacity
- **Aerobic Base (4 days)**: Zone 2 endurance foundation
- **VO2 Max (5 days)**: High-intensity aerobic power
- **Lactate Threshold (5 days)**: Tempo/threshold training

### Strength Movements (Import via seed file)
**File**: `movements_seed.md` (25 common exercises)

Import with: `skrong seed movements movements_seed.md`

**Examples by category**:
- **Upper Push**: Barbell Bench Press, Overhead Press, Incline Dumbbell Press, Dips
- **Upper Pull**: Pull-ups, Barbell Rows, Deadlift (Upper Back Focus)
- **Lower Hinge**: Romanian Deadlift, Conventional Deadlift, Good Mornings
- **Lower Squat**: Back Squat, Front Squat, Bulgarian Split Squat, Leg Press
- **Armor & Isolation**: Lateral Raises, Face Pulls, Bicep Curls, Tricep Extensions, Calf Raises, Farmer's Walks
- **Core & Stability**: Planks, Pallof Press, Russian Twists, Hanging Leg Raises, Hip Thrusts

### Endurance Movements (Optional Import)
**File**: `endurance_movements_seed.md` (12 cardio exercises)

Import with: `skrong seed movements endurance_movements_seed.md`

**Examples by category**:
- **Swim**: Freestyle Swim, Zone 2 Swim, Interval Swim
- **Bike**: Zone 2 Cycling, Tempo Cycling, Interval Cycling, Easy Recovery Ride
- **Run**: Zone 2 Run, Tempo Run, Interval Run, Easy Recovery Run, Long Run

**Note**: Endurance movements map to both cardio targets (Aerobic Base, VO2 Max) and muscle groups (Quadriceps, Hamstrings, Calves) for comprehensive decay tracking.

## Status: V2 Complete ✅

All core features implemented:

**V1 Features**:
- ✅ Database initialization with schema
- ✅ Decay tracking and status reporting
- ✅ Interactive workout logging
- ✅ Movement library management
- ✅ Target (muscle group) management
- ✅ Workout summaries by date
- ✅ Bulk import via seed files
- ✅ Comprehensive test suite (252+ specs)

**V2 Features (Multi-Sport)**:
- ✅ Schema migration system with automatic upgrades
- ✅ Endurance activity support (Swim, Bike, Run)
- ✅ Dual payload parsing (strength + endurance)
- ✅ Dynamic log command with activity type detection
- ✅ Conditional summary formatting
- ✅ Distance/time tracking with pace calculation
- ✅ Brick workout support (mixed sessions)
- ✅ Endurance seed data (categories, targets, movements)
- ✅ Full backward compatibility

## Future Enhancements (Post-V2)
- Export to CSV/JSON
- Historical volume tracking and trends
- Progressive overload metrics
- Primary vs. secondary target weighting
- Custom RPE thresholds per target
- Multi-user support
- Movement notes and form cues
- Rest timer integration
- Distance unit preference (miles vs km)
- Heart rate tracking
- Power metrics (watts) for cycling
- Stroke count for swimming
- Elevation gain tracking
- Multi-lap/interval splits
