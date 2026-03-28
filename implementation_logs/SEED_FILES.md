# Seed Files

Seed files allow you to bulk-import targets and movements into Skrong without using the interactive UI.

## Commands

```bash
# Import targets from a seed file
skrong seed targets targets_seed.md

# Import movements from a seed file
skrong seed movements movements_seed.md
```

## Targets Seed File Format

**File:** `targets_seed.md`

```yaml
# Section Header (optional comment)
- name: "Target Name"
  decay_threshold_days: 5

- name: "Another Target"
  decay_threshold_days: 7
```

### Features:
- Section headers with `#` are ignored (useful for organizing)
- Parenthetical notes in names like `"Pectorals" (Chest)` are removed
- Inline comments after `#` are ignored
- All imported targets default to `is_tracked: true`
- If `decay_threshold_days` is omitted, defaults to 5
- Existing targets are skipped (no duplicates)

### Example:

```yaml
# THE DRIVE TRAIN
- name: "Quadriceps"
  decay_threshold_days: 6
- name: "Hamstrings"
  decay_threshold_days: 6

# THE UPPER ENGINE
- name: "Pectorals" (Chest)
  decay_threshold_days: 5 # Important pushing muscle
```

## Movements Seed File Format

**File:** `movements_seed.md`

```yaml
# Section Header (optional comment)
- name: "Movement Name"
  category: "Category Name"
  targets:
    - "Target 1"
    - "Target 2"
```

### Features:
- Section headers with `#` are ignored
- `category` must match an existing category name:
  - Upper Push
  - Upper Pull
  - Lower Hinge
  - Lower Squat
  - Armor & Isolation
  - Core & Stability
- `targets` must reference existing target names
- Existing movements are skipped (no duplicates)
- Non-existent targets show warnings but movement is still created

### Example:

```yaml
# UPPER PUSH
- name: "Barbell Bench Press"
  category: "Upper Push"
  targets:
    - "Pectorals"
    - "Triceps"
    - "Anterior Deltoids"

- name: "Overhead Press"
  category: "Upper Push"
  targets:
    - "Anterior Deltoids"
    - "Triceps"
```

## Workflow

1. **Initialize database:**
   ```bash
   skrong init
   ```

2. **Import targets first:**
   ```bash
   skrong seed targets targets_seed.md
   ```

3. **Then import movements:**
   ```bash
   skrong seed movements movements_seed.md
   ```

4. **Verify import:**
   ```bash
   skrong targets list
   skrong library list
   ```

## Re-importing

Running seed commands multiple times is safe:
- Existing entries are automatically skipped
- Only new entries are added
- No data is overwritten

This makes it easy to add new targets or movements to your seed files and re-import them.

## Example Files

- `targets_seed.md` - Complete target library with organized muscle groups
- `movements_seed.md` - Example movements covering all categories
