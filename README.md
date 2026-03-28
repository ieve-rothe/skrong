# skrong

**A CLI multi-sport training tracker focused on muscle group recovery and decay tracking.**

Skrong helps you maintain balanced training by tracking when each muscle group was last worked and flagging those that need attention. Supports both strength training (weight/reps) and endurance activities (distance/time). Think of it as a maintenance schedule for your body's machinery.

## Philosophy

Traditional workout trackers focus on progress tracking and PRs. Skrong takes a different approach:

- **Recovery-First**: Each muscle group has a decay threshold - go past it and you'll see warnings
- **Balanced Training**: Status command highlights neglected muscle groups before you train
- **Minimal Friction**: Quick logging via CLI, no app switching or complex UIs
- **Multi-Sport**: Tracks both strength training (weight/reps) and endurance activities (distance/time)
- **Unified Tracking**: All activities count toward muscle group recovery, whether lifting or cardio
- **Flexible Categories**: Organizes movements by biomechanical patterns and sport types

## Features

✅ **Decay Tracking** - Monitor days since last workout per muscle group
✅ **Color-Coded Status** - Green/Yellow/Red indicators for training readiness
✅ **Dual Activity Types** - Strength training (weight/reps) and endurance (distance/time)
✅ **Quick Logging** - Log entire workouts in seconds via CLI with smart format detection
✅ **Pace Calculation** - Automatic pace per mile for endurance efforts
✅ **Brick Workouts** - Log mixed sessions (swim → bike → run) in one flow
✅ **Movement Library** - Custom movements with target muscle associations
✅ **Seed Files** - Bulk import categories, targets, and movements from YAML-like files
✅ **Smart Summaries** - Conditional formatting based on activity type
✅ **Schema Migrations** - Automatic database upgrades preserve existing data
✅ **XDG Compliant** - Data stored in `~/.local/share/skrong/`

## What's New in V2

**Multi-Sport Endurance Tracking** is now available! In addition to strength training, Skrong now supports:
- Swimming, cycling, and running with distance/time tracking
- Automatic pace calculation for endurance efforts
- Brick workout logging (swim → bike → run in one session)
- Cardiovascular system decay tracking
- Unified muscle group monitoring across all activities

Existing users: See [Upgrading from V1](#upgrading-from-v1-strength-only) below for migration instructions.

## Quick Start

```bash
# Build the binary
shards install
crystal build src/skrong.cr -o bin/skrong

# Initialize database and categories
./bin/skrong init

# Import strength training data (optional but recommended)
./bin/skrong seed targets targets_seed.md
./bin/skrong seed movements movements_seed.md

# Import endurance tracking data (optional, for swimmers/cyclists/runners)
./bin/skrong seed categories endurance_categories_seed.md
./bin/skrong seed targets endurance_targets_seed.md
./bin/skrong seed movements endurance_movements_seed.md

# Check what needs attention
./bin/skrong status

# Log a workout (strength or endurance)
./bin/skrong log
```

## Installation

### Prerequisites

- Crystal 1.x or later
- SQLite3

### Build from source

```bash
git clone https://github.com/yourusername/skrong
cd skrong
shards install
crystal build src/skrong.cr -o bin/skrong

# Optionally, add to PATH
sudo ln -s $(pwd)/bin/skrong /usr/local/bin/skrong
```

## Usage

### Initialize Database

```bash
skrong init
```

Creates the database at `~/.local/share/skrong/skrong.db` and seeds 6 default strength categories:
- Upper Push
- Upper Pull
- Lower Hinge
- Lower Squat
- Armor & Isolation
- Core & Stability

**For existing users:** Running `init` again will automatically apply schema migrations to add endurance support while preserving all your data.

### Check Training Status

```bash
skrong status
```

Shows color-coded decay report for all tracked muscle groups:
- **Green (OK)**: Within threshold
- **Yellow (WARN)**: Threshold + 1-2 days
- **Red (CRIT)**: Beyond threshold + 2 days

### Log a Workout

```bash
skrong log
```

Interactive logging flow:
1. Confirm today's date or enter custom date
2. Select movement category (strength or endurance)
3. Select specific movement
4. Enter set data:
   - **Strength**: `weight reps rpe` (e.g., `185 8 7`)
   - **Endurance**: `distance duration rpe` (e.g., `3.1 24:30 7`)
5. Log another set for same movement or switch movements
6. Complete session

**Strength Example:**
```
Log for today (2026-03-24)? (Y/n):
Select category:
  1. Upper Push
  2. Upper Pull
  ...
Enter number (1-6): 1

Upper Push Movements:
  1. Barbell Bench Press
  2. Overhead Press
  ...
Enter number: 1

[Barbell Bench Press]
Enter: weight reps rpe (e.g., 185 8 7): 185 8 7
Set logged: 185.0 x 8 @ RPE 7

Log another set of Barbell Bench Press?
  (r) Repeat movement
  (c) Change movement
  (d) Done with workout
```

**Endurance Example:**
```
Log for today (2026-03-24)? (Y/n):
Select category:
  ...
  7. Swim
  8. Bike
  9. Run
Enter number: 9

Run Movements:
  1. Zone 2 Run
  2. Tempo Run
  3. Interval Run
  ...
Enter number: 1

[Zone 2 Run]
Enter: distance duration rpe (e.g., 3.1 24:30 7): 5 40:00 6
Effort logged: 5.0 mi in 40:00 @ RPE 6

Log another set of Zone 2 Run?
  (r) Repeat movement
  (c) Change movement - enables brick workouts!
  (d) Done with workout
```

### View Workout Summary

```bash
# Today's summary
skrong summary

# Specific date
skrong summary 2026-03-20
```

**Strength Output:**
```
WORKOUT SUMMARY - 2026-03-24
======================================================================
Barbell Bench Press
  Set 1: 185.0 x 8 @ RPE 7
  Set 2: 185.0 x 8 @ RPE 8
  → 2 sets, 2960 total volume

SUMMARY:
  Total movements: 1
  Total sets/efforts: 2
  Total weight lifted: 2960 lbs
  Targets worked: Pectorals, Triceps, Anterior Deltoids
```

**Endurance Output:**
```
WORKOUT SUMMARY - 2026-03-24
======================================================================
Zone 2 Run
  Effort 1: 5.0 mi in 40:00 @ RPE 6 (Pace: 8:00/mi)
  → 1 efforts

SUMMARY:
  Total movements: 1
  Total sets/efforts: 1
  Total distance: 5.0 mi
  Total time: 40:00
  Targets worked: Aerobic Base, Quadriceps, Hamstrings, Calves & Soleus
```

**Mixed Session (Brick Workout):**
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
  Targets worked: Aerobic Base, Pectorals, Quadriceps, Triceps, ...
```

### Manage Movement Library

```bash
# List all movements
skrong library list

# Add new movement (interactive)
skrong library add

# Delete movement
skrong library delete <movement_id>
```

### Manage Targets (Muscle Groups & Cardio Systems)

```bash
# List all targets
skrong targets list

# Add new target (interactive)
skrong targets add

# Edit target properties
skrong targets edit <target_id>

# Delete target
skrong targets delete <target_id>
```

### Bulk Import via Seed Files

See [SEED_FILES.md](SEED_FILES.md) for detailed format documentation.

```bash
# Import custom categories (optional - endurance categories)
skrong seed categories endurance_categories_seed.md

# Import muscle groups
skrong seed targets targets_seed.md

# Import movements
skrong seed movements movements_seed.md
```

**Categories format:**
```yaml
# Endurance Categories
- name: "Swim"
  activity_type: "endurance"
- name: "Bike"
  activity_type: "endurance"
- name: "Run"
  activity_type: "endurance"
```

**Targets format:**
```yaml
# Muscle Groups or Cardio Systems
- name: "Quadriceps"
  decay_threshold_days: 6
- name: "Cardiovascular System"
  decay_threshold_days: 3
```

**Movements format:**
```yaml
# Strength Movement
- name: "Barbell Bench Press"
  category: "Upper Push"
  targets:
    - "Pectorals"
    - "Triceps"
    - "Anterior Deltoids"

# Endurance Movement
- name: "Zone 2 Run"
  category: "Run"
  targets:
    - "Aerobic Base"
    - "Quadriceps"
    - "Hamstrings"
```

Seed files are idempotent - re-running safely skips existing entries.

### Help

```bash
skrong --help
skrong --version
```

## Key Concepts

### Decay Thresholds

Each muscle group has a `decay_threshold_days` that defines how long you can go without training it before warnings appear. Examples:

**Strength Targets:**
- **Fast Recovery (3-4 days)**: Core, grip, calves, rotator cuff
- **Medium Recovery (5 days)**: Chest, lats, shoulders, spinal erectors
- **Slow Recovery (6 days)**: Quads, hamstrings, glutes (high CNS tax)

**Endurance Targets:**
- **Very Fast (3 days)**: Cardiovascular System
- **Fast (4 days)**: Aerobic Base
- **Medium (5 days)**: VO2 Max, Lactate Threshold

### RPE (Rate of Perceived Exertion)

Scale of 1-10 indicating effort level:
- **1-4**: Warm-up, easy recovery efforts
- **5-7**: Working sets/efforts, moderate intensity
- **8-9**: Hard sets/efforts, close to max
- **10**: Absolute max effort

**All sets/efforts count** toward "hitting" a muscle group, regardless of RPE.

### Activity Types

Skrong supports two activity types with different input formats:

**Strength Training:**
- Input: `weight reps rpe` (e.g., `185 8 7`)
- Tracks: Weight lifted, repetitions, RPE
- Output: "185.0 x 8 @ RPE 7"

**Endurance Activities:**
- Input: `distance duration rpe` (e.g., `3.1 24:30 7`)
- Tracks: Distance (miles), duration (MM:SS or HH:MM:SS), RPE
- Output: "3.1 mi in 24:30 @ RPE 7 (Pace: 7:54/mi)"
- Automatic pace calculation per mile

### Movement Categories

**Strength Categories** (biomechanical patterns):
- **Upper Push**: Pressing movements (bench, overhead press)
- **Upper Pull**: Pulling movements (rows, pull-ups)
- **Lower Hinge**: Hip hinge patterns (deadlifts, RDLs)
- **Lower Squat**: Squat patterns (squats, leg press)
- **Armor & Isolation**: Single-joint movements (curls, lateral raises)
- **Core & Stability**: Anti-movement and core work

**Endurance Categories** (sport types):
- **Swim**: Swimming activities (freestyle, intervals, etc.)
- **Bike**: Cycling activities (zone 2, tempo, intervals, etc.)
- **Run**: Running activities (easy, tempo, long runs, etc.)

### Brick Workouts

Log multiple sports in a single session by using the "Change movement" option. Perfect for triathletes:
1. Log swim efforts
2. Change movement → select Bike category
3. Log bike efforts
4. Change movement → select Run category
5. Log run efforts

All logged to the same session with unified summary.

## Architecture

```
skrong/
├── src/
│   ├── skrong.cr           # Main entry point
│   ├── cli.cr              # Command routing
│   ├── db/
│   │   ├── connection.cr   # Singleton DB connection
│   │   └── migrations.cr   # Schema and category seeding
│   ├── models/
│   │   ├── category.cr     # Movement categories
│   │   ├── target.cr       # Muscle groups
│   │   ├── movement.cr     # Exercises
│   │   ├── session.cr      # Workout sessions
│   │   ├── set.cr          # Individual sets
│   │   └── decay.cr        # Decay calculation engine
│   ├── ui/
│   │   ├── colors.cr       # ANSI color utilities
│   │   ├── prompt.cr       # Input parsing/validation
│   │   ├── select.cr       # Selection prompts
│   │   └── table.cr        # Status report rendering
│   └── commands/
│       ├── init.cr         # Database initialization
│       ├── status.cr       # Decay status report
│       ├── log.cr          # Workout logging
│       ├── summary.cr      # Workout summaries
│       ├── library.cr      # Movement management
│       ├── targets.cr      # Target management
│       └── seed.cr         # Bulk import
└── spec/                   # Comprehensive test suite
```

### Database Schema

```sql
schema_version    # Migration tracking
categories        # Movement categories with activity_type (6 strength default)
targets           # Muscle groups/cardio systems with decay thresholds
movements         # Exercises linked to category
movement_targets  # Junction table: movements ↔ targets
sessions          # Workout sessions (date-based)
sets              # Individual sets/efforts (weight+reps OR distance+duration, RPE)
```

**Key Schema Features:**
- `categories.activity_type`: 'strength' or 'endurance' - determines input format
- `sets` table supports both:
  - Strength: `weight` (float) + `reps` (int)
  - Endurance: `distance` (float) + `duration_seconds` (int)
- Automatic schema migrations preserve existing data

## Development

### Running Tests

```bash
# Run full test suite
crystal spec

# Run specific test file
crystal spec spec/commands/log_spec.cr

# Run specific test
crystal spec spec/commands/log_spec.cr:15
```

**Test Coverage**: 260+ specs with comprehensive coverage of all commands, models, endurance features, and edge cases.

### Building

```bash
# Development build
crystal build src/skrong.cr -o bin/skrong

# Release build (optimized)
crystal build src/skrong.cr -o bin/skrong --release
```

### Code Structure

- **TDD Approach**: All features developed test-first
- **Singleton Pattern**: Database connection management
- **Command Pattern**: Each command is a separate module
- **Separation of Concerns**: Models, UI, Commands clearly separated
- **Validation**: Input validation with retry loops
- **XDG Compliance**: Respects `$XDG_DATA_HOME`

## Upgrading from V1 (Strength Only)

If you've been using Skrong for strength training and want to add endurance tracking:

1. **Backup your data** (recommended):
   ```bash
   cp ~/.local/share/skrong/skrong.db ~/.local/share/skrong/skrong.db.backup
   ```

2. **Rebuild the binary** with latest code:
   ```bash
   git pull
   crystal build src/skrong.cr -o bin/skrong
   ```

3. **Apply migrations** (preserves all existing data):
   ```bash
   ./bin/skrong init
   # Output: "Migrations applied (if any)."
   ```

4. **Import endurance data** (optional):
   ```bash
   ./bin/skrong seed categories endurance_categories_seed.md
   ./bin/skrong seed targets endurance_targets_seed.md
   ./bin/skrong seed movements endurance_movements_seed.md
   ```

Your existing strength training data remains completely unchanged. You can continue using Skrong exactly as before, or start logging endurance activities alongside your lifting.

## Contributing

1. Fork it (<https://github.com/yourusername/skrong/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write tests first (TDD)
4. Implement feature
5. Ensure all tests pass (`crystal spec`)
6. Commit your changes (`git commit -am 'Add some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create a new Pull Request

## License

MIT

## Contributors

- [cam](https://github.com/yourusername) - creator and maintainer
