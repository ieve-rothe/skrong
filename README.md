# skrong

**A CLI workout tracker focused on muscle group recovery and decay tracking.**

Skrong helps you maintain balanced training by tracking when each muscle group was last worked and flagging those that need attention. Think of it as a maintenance schedule for your body's machinery.

## Philosophy

Traditional workout trackers focus on progress tracking and PRs. Skrong takes a different approach:

- **Recovery-First**: Each muscle group has a decay threshold - go past it and you'll see warnings
- **Balanced Training**: Status command highlights neglected muscle groups before you train
- **Minimal Friction**: Quick logging via CLI, no app switching or complex UIs
- **RPE-Based**: Only sets with RPE ≥ 5 count as "hitting" a muscle group
- **Flexible Categories**: Organizes movements by biomechanical patterns, not body parts

## Features

✅ **Decay Tracking** - Monitor days since last qualified workout per muscle group
✅ **Color-Coded Status** - Green/Yellow/Red indicators for training readiness
✅ **Quick Logging** - Log entire workouts in seconds via CLI
✅ **Movement Library** - Custom movements with target muscle associations
✅ **Seed Files** - Bulk import targets and movements from YAML-like files
✅ **Workout Summaries** - Review training history by date
✅ **RPE Filtering** - Only meaningful sets (RPE ≥ 5) count toward recovery
✅ **XDG Compliant** - Data stored in `~/.local/share/skrong/`

## Quick Start

```bash
# Build the binary
shards install
crystal build src/skrong.cr -o bin/skrong

# Initialize database and categories
./bin/skrong init

# Import muscle groups and movements (optional but recommended)
./bin/skrong seed targets targets_seed.md
./bin/skrong seed movements movements_seed.md

# Check what needs attention
./bin/skrong status

# Log a workout
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

Creates the database at `~/.local/share/skrong/skrong.db` and seeds 6 default categories:
- Upper Push
- Upper Pull
- Lower Hinge
- Lower Squat
- Armor & Isolation
- Core & Stability

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
2. Select movement category
3. Select specific movement
4. Enter set data: `weight reps rpe` (e.g., `185 8 7`)
5. Log another set for same movement or switch movements
6. Complete session

**Example:**
```
Log for today (2026-03-24)? (Y/n):
Select category:
  1. Upper Push
  2. Upper Pull
  ...
Enter number (1-6): 1

Select movement:
  1. Barbell Bench Press
  2. Overhead Press
  ...
Enter number: 1

Barbell Bench Press
Enter set (weight reps rpe): 185 8 7
Set logged: 185.0 x 8 @ RPE 7

Log another set for Barbell Bench Press?
  (r) Repeat movement
  (c) Change movement
  (d) Done with workout
```

### View Workout Summary

```bash
# Today's summary
skrong summary

# Specific date
skrong summary 2026-03-20
```

Shows:
- All movements performed
- Individual set details
- Total volume per movement
- Muscle groups trained
- Aggregate statistics

### Manage Movement Library

```bash
# List all movements
skrong library list

# Add new movement (interactive)
skrong library add

# Delete movement
skrong library delete <movement_id>
```

### Manage Targets (Muscle Groups)

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
# Import muscle groups
skrong seed targets targets_seed.md

# Import movements
skrong seed movements movements_seed.md
```

**Targets format:**
```yaml
# Section Header
- name: "Quadriceps"
  decay_threshold_days: 6
- name: "Hamstrings"
  decay_threshold_days: 6
```

**Movements format:**
```yaml
- name: "Barbell Bench Press"
  category: "Upper Push"
  targets:
    - "Pectorals"
    - "Triceps"
    - "Anterior Deltoids"
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

- **Fast Recovery (3-4 days)**: Core, grip, calves, rotator cuff
- **Medium Recovery (5 days)**: Chest, lats, shoulders, spinal erectors
- **Slow Recovery (6 days)**: Quads, hamstrings, glutes (high CNS tax)

### RPE (Rate of Perceived Exertion)

Scale of 1-10 indicating set difficulty:
- **1-4**: Warm-up sets, not counted toward "hitting" a muscle
- **5-7**: Working sets, counted as qualified training
- **8-9**: Hard sets, close to failure
- **10**: Absolute max effort

Only sets with RPE ≥ 5 count as legitimately training a muscle group.

### Movement Categories

Movements are organized by biomechanical pattern, not body part:
- **Upper Push**: Pressing movements (bench, overhead press)
- **Upper Pull**: Pulling movements (rows, pull-ups)
- **Lower Hinge**: Hip hinge patterns (deadlifts, RDLs)
- **Lower Squat**: Squat patterns (squats, leg press)
- **Armor & Isolation**: Single-joint movements (curls, lateral raises)
- **Core & Stability**: Anti-movement and core work

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
categories        # Movement categories (6 default)
targets           # Muscle groups with decay thresholds
movements         # Exercises linked to category
movement_targets  # Junction table: movements ↔ targets
sessions          # Workout sessions (date-based)
sets              # Individual sets (weight, reps, RPE)
```

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

**Test Coverage**: 252 specs with comprehensive coverage of all commands, models, and edge cases.

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
