# Endurance Tracking Implementation Summary

## Overview
Skrong now supports tracking endurance activities (swimming, cycling, running) in addition to strength training. This implementation maintains full backward compatibility with existing strength training data while adding comprehensive endurance tracking capabilities.

## What Was Implemented

### 1. Database Schema Changes
- **Categories table**: Added `activity_type` column (default: 'strength')
- **Sets table**:
  - Made `weight` and `reps` nullable
  - Added `distance` (REAL) and `duration_seconds` (INTEGER) columns
- **Migration system**: Automatic schema migration for existing databases via `skrong init`

### 2. Dual Payload Parsers
- **Strength format**: `weight reps rpe` (e.g., `185 8 7`)
- **Endurance format**: `distance duration rpe` (e.g., `3.1 24:30 7`)
  - Duration supports `MM:SS` and `HH:MM:SS` formats
  - Distance in miles (can be decimal)

### 3. Dynamic Logging Flow
The `skrong log` command automatically adapts based on activity type:
- Selects appropriate prompt based on category's `activity_type`
- Validates format specific to activity type
- Stores data in correct fields
- Displays formatted confirmation messages

### 4. Enhanced Reporting
The `skrong summary` command now:
- Detects set type (strength vs endurance)
- **Strength sets**: `"185.0 x 8 @ RPE 7"`
- **Endurance efforts**: `"3.1 mi in 24:30 @ RPE 7 (Pace: 7:54/mi)"`
- Aggregates metrics separately:
  - Total weight lifted (lbs)
  - Total distance (miles)
  - Total time (HH:MM:SS format)

### 5. Seed Data Files
Three new seed files for quick setup:
- `endurance_categories_seed.md` - Swim, Bike, Run categories
- `endurance_targets_seed.md` - Cardiovascular System, Aerobic Base, VO2 Max, Lactate Threshold
- `endurance_movements_seed.md` - 12 pre-configured endurance movements

## Migration Instructions

### For Existing Users
1. **Backup your data** (recommended):
   ```bash
   cp ~/.local/share/skrong/skrong.db ~/.local/share/skrong/skrong.db.backup
   ```

2. **Apply migrations**:
   ```bash
   ./bin/skrong init
   ```
   This will update your schema while preserving all existing data.

3. **Import endurance data** (optional):
   ```bash
   ./bin/skrong seed categories endurance_categories_seed.md
   ./bin/skrong seed targets endurance_targets_seed.md
   ./bin/skrong seed movements endurance_movements_seed.md
   ```

### For New Users
Simply run `./bin/skrong init` to get the updated schema from the start.

## Usage Examples

### Logging a Strength Set
```
$ skrong log
Log for today (2026-03-28)? (Y/n): y

Select category:
  1. Upper Push
  2. Upper Pull
  [...]

Enter number (1-6): 1

Upper Push Movements:
  1. Push-ups
  2. Seated DB Overhead Press
  [...]

Enter number (1-4): 2

[Seated DB Overhead Press]
(b to go back, q to quit)
Enter: weight reps rpe (e.g., 185 8 7): 50 12 7
Set logged: 50.0 x 12 @ RPE 7
```

### Logging an Endurance Effort
```
$ skrong log
Log for today (2026-03-28)? (Y/n): y

Select category:
  [...]
  7. Swim
  8. Bike
  9. Run

Enter number (1-9): 9

Run Movements:
  1. Zone 2 Run
  2. Tempo Run
  3. Interval Run
  [...]

Enter number (1-5): 1

[Zone 2 Run]
(b to go back, q to quit)
Enter: distance duration rpe (e.g., 3.1 24:30 7): 5 40:00 6
Effort logged: 5.0 mi in 40:00 @ RPE 6
```

### Viewing Mixed Summary
```
$ skrong summary

======================================================================
WORKOUT SUMMARY - 2026-03-28
======================================================================

Seated DB Overhead Press
  Set 1: 50.0 x 12 @ RPE 7
  Set 2: 50.0 x 10 @ RPE 8
  → 2 sets, 1100 total volume

Zone 2 Run
  Effort 1: 5.0 mi in 40:00 @ RPE 6 (Pace: 8:00/mi)
  → 1 efforts

----------------------------------------------------------------------
SUMMARY:
  Total movements: 2
  Total sets/efforts: 3
  Total weight lifted: 1100 lbs
  Total distance: 5.0 mi
  Total time: 40:00
  Targets worked: Aerobic Base, Anterior Deltoids, Calves & Soleus, [...]
======================================================================
```

## Technical Details

### Model Changes
- **Category model**: Added `activity_type` property
- **Set model**:
  - Added nullable weight/reps and distance/duration_seconds
  - New methods: `strength_set?()`, `endurance_set?()`, `format_duration()`, `calculate_pace()`
  - Updated `to_s()` for conditional formatting
  - New `create_endurance()` method

### Decay Tracking
All activities (strength and endurance) contribute to muscle group decay tracking via the existing `movement_targets` junction table. For example:
- "Zone 2 Run" hits: Aerobic Base, Quadriceps, Hamstrings, Calves
- Any RPE effort counts toward resetting the decay timer

### Brick Workouts
The existing "Sticky Loop" (repeat/change/done) naturally supports brick workouts:
1. Log a swim effort
2. Choose "Change movement"
3. Log a bike effort
4. Choose "Change movement"
5. Log a run effort
All logged to the same session!

## Files Modified
- `src/db/migrations.cr` - Schema updates and migration system
- `src/models/category.cr` - Added activity_type support
- `src/models/set.cr` - Nullable fields, endurance methods, formatting
- `src/ui/prompt.cr` - Endurance payload parser
- `src/commands/log.cr` - Dynamic prompts based on activity type
- `src/commands/summary.cr` - Conditional formatting
- `src/commands/seed.cr` - Category import support
- `src/commands/init.cr` - Always apply migrations
- `src/cli.cr` - Added `seed categories` subcommand

## Test Coverage
- All existing 252+ specs continue to pass
- Added 10+ new specs for endurance payload parsing
- Schema migration specs verify backward compatibility

## Future Enhancements (Not Implemented)
- Distance unit preference (miles vs km)
- Pace calculation per km
- Heart rate tracking
- Power metrics (watts) for cycling
- Stroke count for swimming
- Elevation gain tracking
- Multi-lap splits
