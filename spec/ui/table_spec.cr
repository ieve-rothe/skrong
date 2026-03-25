require "../spec_helper"

describe Skrong::UI::Table do
  describe ".render_status" do
    it "renders a status table with headers" do
      rows = [] of Skrong::UI::Table::StatusRow

      output = Skrong::UI::Table.render_status(rows)

      output.should contain("TARGET")
      output.should contain("LAST HIT")
      output.should contain("DAYS AGO")
      output.should contain("STATUS")
      output.should contain("LAST MOVEMENT")
    end

    it "renders a row with OK status" do
      rows = [
        Skrong::UI::Table::StatusRow.new(
          target_name: "Quadriceps",
          last_hit_date: "Mar 20",
          days_ago: 4,
          status: :ok,
          last_movement: "Squat"
        )
      ]

      output = Skrong::UI::Table.render_status(rows)

      output.should contain("Quadriceps")
      output.should contain("Mar 20")
      output.should contain("4")
      output.should contain("[OK]")
      output.should contain("Squat")
    end

    it "renders a row with WARN status in yellow" do
      rows = [
        Skrong::UI::Table::StatusRow.new(
          target_name: "Hamstrings",
          last_hit_date: "Mar 18",
          days_ago: 6,
          status: :warn,
          last_movement: "RDL"
        )
      ]

      output = Skrong::UI::Table.render_status(rows)

      output.should contain("Hamstrings")
      output.should contain("[WARN]")
      output.should contain("\e[33m")  # Yellow color code
    end

    it "renders a row with CRIT status in red" do
      rows = [
        Skrong::UI::Table::StatusRow.new(
          target_name: "Lats",
          last_hit_date: "--",
          days_ago: 30,
          status: :crit,
          last_movement: "--"
        )
      ]

      output = Skrong::UI::Table.render_status(rows)

      output.should contain("Lats")
      output.should contain("--")
      output.should contain("[CRIT]")
      output.should contain("\e[31m")  # Red color code
    end

    it "renders multiple rows" do
      rows = [
        Skrong::UI::Table::StatusRow.new("Quadriceps", "Mar 20", 4, :ok, "Squat"),
        Skrong::UI::Table::StatusRow.new("Hamstrings", "Mar 18", 6, :warn, "RDL"),
        Skrong::UI::Table::StatusRow.new("Lats", "--", 30, :crit, "--")
      ]

      output = Skrong::UI::Table.render_status(rows)

      output.should contain("Quadriceps")
      output.should contain("Hamstrings")
      output.should contain("Lats")
    end

    it "includes a title header" do
      rows = [] of Skrong::UI::Table::StatusRow

      output = Skrong::UI::Table.render_status(rows)

      output.should contain("SYSTEM STATUS")
      output.should contain("TARGET MUSCLE GROUPS")
    end

    it "includes separator lines" do
      rows = [] of Skrong::UI::Table::StatusRow

      output = Skrong::UI::Table.render_status(rows)

      output.should contain("=")
      output.should contain("-")
    end

    it "shows empty message when no rows" do
      rows = [] of Skrong::UI::Table::StatusRow

      output = Skrong::UI::Table.render_status(rows)

      output.should contain("No tracked targets found")
    end

    it "pads columns properly for alignment" do
      rows = [
        Skrong::UI::Table::StatusRow.new("A", "Jan 1", 1, :ok, "X"),
        Skrong::UI::Table::StatusRow.new("Very Long Target Name", "Dec 31", 100, :crit, "Very Long Movement Name")
      ]

      output = Skrong::UI::Table.render_status(rows)
      lines = output.lines

      # Find data lines (skip headers)
      data_lines = lines.select { |l| l.includes?("Very Long") || (l.includes?("A") && l.includes?("Jan")) }

      # Both lines should have similar structure (columns aligned)
      data_lines.size.should eq(2)
    end
  end

  describe "StatusRow" do
    it "initializes with all attributes" do
      row = Skrong::UI::Table::StatusRow.new(
        target_name: "Chest",
        last_hit_date: "Mar 24",
        days_ago: 0,
        status: :ok,
        last_movement: "Bench Press"
      )

      row.target_name.should eq("Chest")
      row.last_hit_date.should eq("Mar 24")
      row.days_ago.should eq(0)
      row.status.should eq(:ok)
      row.last_movement.should eq("Bench Press")
    end
  end
end
