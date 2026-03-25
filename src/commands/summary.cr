module Skrong
  module Commands
    module Summary
      # Shows a summary of workouts from a specific date
      def self.run(date : Time? = nil, output : IO = STDOUT, today : Time = Time.local)
        target_date = date || today

        output.puts
        output.puts "=" * 70
        output.puts "WORKOUT SUMMARY - #{target_date.to_s("%Y-%m-%d")}"
        output.puts "=" * 70
        output.puts

        # Find all sessions for this date
        sessions = Models::Session.find_by_date(target_date)

        if sessions.empty?
          output.puts "No workouts logged for #{target_date.to_s("%Y-%m-%d")}."
          output.puts
          return
        end

        # Get all sets from these sessions
        all_sets = [] of Models::Set
        sessions.each do |session|
          all_sets.concat(Models::Set.find_by_session(session.id))
        end

        # Group sets by movement
        sets_by_movement = all_sets.group_by(&.movement_id)

        # Track unique targets
        targets_worked = Set(String).new

        # Display each movement's summary
        sets_by_movement.each do |movement_id, sets|
          movement = Models::Movement.find(movement_id)
          next unless movement

          output.puts UI::Colors.bold(movement.name)

          # Get targets for this movement
          movement.targets.each do |t|
            target = Models::Target.find(t[:target_id])
            targets_worked << target.name if target
          end

          # Show each set
          sets.each_with_index do |set, index|
            output.puts "  Set #{index + 1}: #{set.weight} x #{set.reps} @ RPE #{set.rpe}"
          end

          # Calculate total volume (weight x reps for all sets)
          total_volume = sets.sum { |s| s.weight * s.reps }

          output.puts "  → #{sets.size} sets, #{total_volume.to_i} total volume"
          output.puts
        end

        # Show summary statistics
        output.puts "-" * 70
        output.puts "SUMMARY:"
        output.puts "  Total movements: #{sets_by_movement.size}"
        output.puts "  Total sets: #{all_sets.size}"

        unless targets_worked.empty?
          output.puts "  Targets worked: #{targets_worked.to_a.sort.join(", ")}"
        end

        output.puts "=" * 70
        output.puts
      end
    end
  end
end
