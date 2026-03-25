# Skrong Architecture

## Overview
A CLI-based workout tracking system that monitors muscle group training frequency and alerts on decay. Built in Crystal for fast execution and minimal friction.

## Tech Stack
- **Language**: Crystal
- **Database**: SQLite (embedded, via `crystal-sqlite3` shard)
- **CLI Framework**: Built-in OptionParser + custom prompts
- **Terminal I/O**: Raw mode via `LibC.tcgetattr`/`tcsetattr` for arrow key capture
- **Deployment**: Compiled static binary

## Technical Requirements
- **Keyboard Navigation**: Capture arrow keys (↑/↓) in raw terminal mode for interactive selection
- **Input Parsing**: Robust space-delimited parser for `weight reps rpe` format
- **Date Validation**: Accept YYYY-MM-DD format, validate against reasonable date ranges
- **Performance**: Sub-100ms response time for `status` command with 1000+ sets

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
| name | TEXT NOT NULL UNIQUE | e.g., "Upper Push", "Lower Hinge" |
| display_order | INTEGER DEFAULT 0 | Order for displaying in menus |

**Default Categories**:
1. Upper Push
2. Upper Pull
3. Lower Hinge
4. Lower Squat
5. Armor & Isolation
6. Core & Stability

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
Individual set performance data.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto-increment |
| session_id | INTEGER NOT NULL | Foreign key to sessions |
| movement_id | INTEGER NOT NULL | Foreign key to movements |
| weight | REAL NOT NULL | Weight in user's preferred unit |
| reps | INTEGER NOT NULL | Repetitions completed |
| rpe | INTEGER NOT NULL | Rate of Perceived Exertion (1-10) |

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
**Interactive logging flow** for entering workout data.

**Flow**:

**Phase 1: Session Initialization**
```
$ skrong log
Log for today? (y/n):
```
- If `y`: Session date = today
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

Enter number (or use ↑/↓):
```
- User can type number `1-6` OR use arrow keys to navigate and press Enter
- Filters movements by selected category

**Phase 3: Movement Selection**
```
[Category Name] Movements:
  1. Bench Press
  2. Overhead Press
  3. Dips
  ...

Enter number (or use ↑/↓):
```
- Display filtered movements for selected category
- User can type number OR use arrow keys + Enter

**Phase 4: Payload Entry (Fast Entry)**
```
[Movement Name]
Enter: weight reps rpe (e.g., 40 15 8):
```
- Space-delimited input: `[weight] [reps] [rpe]`
- Example: `40 15 8` → weight=40, reps=15, rpe=8
- Validates: weight > 0, reps > 0, rpe 1-10
- Creates set in database

**Phase 5: Sticky Loop**
```
Log another set of [Movement Name]? (y/n/c)
  y - Log another set (defaults to previous weight/reps)
  n - Done, exit to summary
  c - Change movement
```
- **`y` (Yes)**: Prompt for payload again, but pre-fills with previous `weight reps rpe`. User can hit Enter to accept or type new values.
- **`c` (Change)**: Return to Phase 2 (Category Selection) to pick a new movement
- **`n` (Done)**: Exit logging, show session summary

**Session Summary** (after exit):
```
Session logged for [date]:
  - [N] sets across [M] movements
  - [X] muscle groups targeted
```

### `skrong library`
**Movement management interface**.

**Subcommands**:
- `skrong library list` - Show all movements grouped by category with their targets
- `skrong library add` - Add new movement (interactive prompts for name, category, targets)
- `skrong library edit <movement_id>` - Edit existing movement
- `skrong library delete <movement_id>` - Remove movement (with confirmation)
- `skrong library categories` - List all categories (for reference)

### `skrong init`
**Database initialization**. Creates SQLite database and tables. Should be idempotent.

## Business Logic Rules

### RPE Threshold Rule
**Only sets with RPE >= 5 count as "hitting" a muscle group.**

When calculating "Last Hit" for a target:
```sql
SELECT MAX(sessions.date)
FROM sets
JOIN sessions ON sets.session_id = sessions.id
JOIN movement_targets ON sets.movement_id = movement_targets.movement_id
WHERE movement_targets.target_id = ? AND sets.rpe >= 5
```

### Payload Parsing
Space-delimited input format: `[weight] [reps] [rpe]`

**Examples**:
- `40 15 8` → weight=40.0, reps=15, rpe=8
- `135.5 5 9` → weight=135.5, reps=5, rpe=9
- `225 3 10` → weight=225.0, reps=3, rpe=10

**Validation**:
- Weight: decimal allowed, must be > 0
- Reps: integer only, must be > 0
- RPE: integer only, must be 1-10

**Error handling**: If parsing fails, show format example and re-prompt.

### Sticky Loop Defaults
When user selects "y" to log another set of the same movement:
1. Show previous values: `Previous: 40 15 8`
2. Prompt: `Enter (↵ to repeat, or new values):`
3. If user presses Enter with no input → use previous values
4. If user enters new payload → parse and use new values

**State Management**: Track `last_weight`, `last_reps`, `last_rpe` for current movement within session.

### Target Weighting (V1)
**Primary and secondary targets are treated equally.** Both reset the "Last Hit" timer. Future versions may implement differential weighting.

### Decay Calculation
For each target:
1. Find most recent session date where target was hit with RPE >= 5
2. Calculate `days_since = (TODAY - last_hit_date)` in days
3. Determine status:
   - `days_since <= decay_threshold_days` → OK
   - `days_since <= decay_threshold_days + 2` → WARN
   - `days_since > decay_threshold_days + 2` → CRIT
4. If no qualifying sets exist: CRIT with "Last Hit" as "--"

## File Structure
```
src/
├── skrong.cr              # Main entry point, CLI routing
├── commands/
│   ├── status.cr          # Status report generator
│   ├── log.cr             # Interactive logging flow
│   ├── library.cr         # Movement CRUD operations
│   └── init.cr            # Database initialization
├── models/
│   ├── category.cr        # Category model & queries
│   ├── target.cr          # Target model & queries
│   ├── movement.cr        # Movement model & queries
│   ├── session.cr         # Session model & queries
│   └── set.cr             # Set model & queries
├── db/
│   ├── connection.cr      # SQLite connection handler
│   └── migrations.cr      # Schema creation logic
└── ui/
    ├── prompt.cr          # Input prompt helpers (text, date, payload parsing)
    ├── select.cr          # Interactive selection with keyboard nav (↑/↓ + number input)
    ├── table.cr           # Status table renderer
    └── colors.cr          # Terminal color utilities
```

**UI Component Notes**:
- `select.cr` handles both keyboard navigation (arrow keys) and number input
- Requires raw terminal mode for capturing arrow key input
- Falls back to number-only input if terminal doesn't support raw mode

## Database Location
`~/.local/share/skrong/skrong.db` (follows XDG Base Directory spec)

## Implementation Phases

### Phase 1: Core Data Layer
1. Database connection and schema creation (including `categories` table)
2. Model classes with basic CRUD (Category, Target, Movement, Session, Set)
3. `skrong init` command
4. Seed default categories (6 macro categories)

### Phase 2: Basic UI Components
1. Text input prompts (`ui/prompt.cr`)
2. Date input validation (YYYY-MM-DD format)
3. Payload parser (space-delimited: `weight reps rpe`)
4. Color output utilities

### Phase 3: Interactive Selection
1. Keyboard navigation component (`ui/select.cr`)
2. Arrow key capture (↑/↓) in raw terminal mode
3. Number input fallback
4. List rendering with selection highlight

### Phase 4: Logging Flow
1. `skrong log` session initialization (date prompt)
2. Category selection menu
3. Movement selection (filtered by category)
4. Payload entry and set creation
5. Sticky loop with defaults (y/n/c options)
6. Session summary output

### Phase 5: Reporting Engine
1. Decay calculation query (using `sessions.date`)
2. Status table rendering
3. Terminal color output (OK/WARN/CRIT)
4. `skrong status` command

### Phase 6: Movement Management
1. `skrong library list` - grouped by category
2. `skrong library add` - with category selection
3. `skrong library edit` and `delete`
4. `skrong library categories` command

### Phase 7: Polish
1. Error handling and user feedback
2. Input validation and edge cases
3. Help text and usage examples
4. Default seed data for common movements

## Default Seed Data

### Categories (Required)
The 6 macro categories must be seeded on `skrong init`:
1. Upper Push
2. Upper Pull
3. Lower Hinge
4. Lower Squat
5. Armor & Isolation
6. Core & Stability

### Targets (Optional)
Common muscle groups to reduce setup friction:
- Quadriceps, Hamstrings, Glutes
- Chest (Pecs), Lats, Traps, Rear Delts
- Front Delts, Side Delts, Rotator Cuff
- Triceps, Biceps, Forearms
- Spinal Erectors, Deep Core, Obliques
- Anterior Tibialis, Calves

### Movements (Optional)
Common exercises mapped to categories and targets:
- **Upper Push**: Bench Press, Overhead Press, Dips, Incline Press
- **Upper Pull**: Pull-ups, Rows, Face Pulls, Shrugs
- **Lower Hinge**: Deadlift, RDL, Good Mornings, Nordic Curls
- **Lower Squat**: Back Squat, Front Squat, Lunges, Leg Press
- **Armor & Isolation**: Lateral Raises, Curls, Tricep Extensions, Calf Raises
- **Core & Stability**: Planks, Pallof Press, Ab Wheel, Bird Dogs

## Future Enhancements (Post-V1)
- Export to CSV/JSON
- Historical volume tracking
- Progressive overload metrics
- Primary vs. secondary target weighting
- Custom RPE thresholds per target
- Multi-user support
