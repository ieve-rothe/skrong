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

        # Track totals separately for strength and endurance
        total_weight_lifted = 0.0
        total_distance = 0.0
        total_duration = 0

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

          # Check if this is strength or endurance
          first_set = sets.first
          if first_set.strength_set?
            # Show each strength set
            sets.each_with_index do |set, index|
              output.puts "  Set #{index + 1}: #{set.weight} x #{set.reps} @ RPE #{set.rpe}"
            end

            # Calculate total volume (weight x reps for all sets)
            total_volume = sets.sum { |s| (s.weight || 0.0) * (s.reps || 0) }
            total_weight_lifted += total_volume

            output.puts "  → #{sets.size} sets, #{total_volume.to_i} total volume"
          elsif first_set.endurance_set?
            # Show each endurance effort
            sets.each_with_index do |set, index|
              dist = set.distance || 0.0
              dur = set.duration_seconds || 0
              pace = set.calculate_pace(dist, dur)
              formatted_duration = set.format_duration(dur)
              output.puts "  Effort #{index + 1}: #{dist} mi in #{formatted_duration} @ RPE #{set.rpe} (Pace: #{pace})"

              total_distance += dist
              total_duration += dur
            end

            output.puts "  → #{sets.size} efforts"
          end

          output.puts
        end

        # Show summary statistics
        output.puts "-" * 70
        output.puts "SUMMARY:"
        output.puts "  Total movements: #{sets_by_movement.size}"
        output.puts "  Total sets/efforts: #{all_sets.size}"

        # Show strength metrics if any
        if total_weight_lifted > 0
          output.puts "  Total weight lifted: #{total_weight_lifted.to_i} lbs"
        end

        # Show endurance metrics if any
        if total_distance > 0
          output.puts "  Total distance: #{total_distance.round(2)} mi"
          # Format total duration using the Set helper (create a dummy set for formatting)
          hours = total_duration // 3600
          minutes = (total_duration % 3600) // 60
          secs = total_duration % 60
          formatted_duration = if hours > 0
                                 "#{hours}:#{"#{minutes}".rjust(2, '0')}:#{"#{secs}".rjust(2, '0')}"
                               else
                                 "#{minutes}:#{"#{secs}".rjust(2, '0')}"
                               end
          output.puts "  Total time: #{formatted_duration}"
        end

        unless targets_worked.empty?
          output.puts "  Targets worked: #{targets_worked.to_a.sort.join(", ")}"
        end

        output.puts "=" * 70
        output.puts
      end
    end
  end
end
