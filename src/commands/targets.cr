module Skrong
  module Commands
    module Targets
      # Lists all targets with their properties
      def self.list(output : IO = STDOUT)
        targets = Models::Target.all

        if targets.empty?
          output.puts "No targets in the system."
          output.puts "Run 'skrong targets add' to add targets."
          return
        end

        output.puts
        output.puts "TARGET LIBRARY"
        output.puts "=" * 80
        output.puts

        # Table header
        output.puts sprintf("%-4s %-30s %-10s %-15s", "ID", "Name", "Tracked", "Decay Days")
        output.puts "-" * 80

        targets.each do |target|
          tracked_str = target.is_tracked ? "Yes" : "No"
          output.puts sprintf("%-4d %-30s %-10s %-15d",
            target.id,
            target.name,
            tracked_str,
            target.decay_threshold_days
          )
        end

        output.puts "=" * 80
        output.puts
      end

      # Adds a new target to the system
      def self.add(input : IO = STDIN, output : IO = STDOUT)
        output.puts "Add New Target"
        output.puts "=" * 40
        output.puts

        # Enter target name
        output.print "Enter target name (muscle group): "
        output.flush
        name = input.gets.try(&.strip) || ""

        if name.empty?
          output.puts "Target name cannot be empty."
          return
        end

        # Ask if tracked
        output.print "Track this target in status report? (Y/n): "
        output.flush
        tracked_input = input.gets.try(&.strip.downcase) || "y"
        is_tracked = tracked_input == "n" ? false : true

        # Ask for decay threshold
        decay_days = 5 # default
        output.print "Decay threshold in days (default: 5): "
        output.flush
        threshold_input = input.gets.try(&.strip) || ""

        unless threshold_input.empty?
          loop do
            begin
              decay_days = threshold_input.to_i
              if decay_days <= 0
                output.puts "Decay threshold must be greater than 0."
                output.print "Enter decay threshold: "
                output.flush
                threshold_input = input.gets.try(&.strip) || "5"
                next
              end
              break
            rescue ArgumentError
              output.puts "Invalid number."
              output.print "Enter decay threshold: "
              output.flush
              threshold_input = input.gets.try(&.strip) || "5"
            end
          end
        end

        # Create the target
        target = Models::Target.create(name, is_tracked: is_tracked, decay_threshold_days: decay_days)

        output.puts
        output.puts "Target added successfully!"
        output.puts "  Name: #{target.name}"
        output.puts "  ID: #{target.id}"
        output.puts "  Tracked: #{target.is_tracked ? "Yes" : "No"}"
        output.puts "  Decay threshold: #{target.decay_threshold_days} days"
      end

      # Deletes a target from the system
      def self.delete(target_id : Int64, input : IO = STDIN, output : IO = STDOUT)
        target = Models::Target.find(target_id)

        unless target
          output.puts "Target with ID #{target_id} not found."
          return
        end

        output.puts "Delete Target"
        output.puts "=" * 40
        output.puts "Target: #{target.name}"
        output.puts "ID: #{target.id}"
        output.puts

        output.print "Are you sure you want to delete this target? (y/n): "
        output.flush

        confirmation = input.gets.try(&.strip.downcase) || ""

        if confirmation == "y"
          # Delete the target
          db = DB::Connection.instance

          # Note: This will leave orphaned movement_targets entries
          # In production, you might want to handle this differently
          db.exec("DELETE FROM targets WHERE id = ?", target_id)

          output.puts "Target deleted successfully."
        else
          output.puts "Deletion cancelled."
        end
      end

      # Edits an existing target
      def self.edit(target_id : Int64, input : IO = STDIN, output : IO = STDOUT)
        target = Models::Target.find(target_id)

        unless target
          output.puts "Target with ID #{target_id} not found."
          return
        end

        output.puts "Edit Target"
        output.puts "=" * 40
        output.puts "Current values:"
        output.puts "  Name: #{target.name}"
        output.puts "  Tracked: #{target.is_tracked ? "Yes" : "No"}"
        output.puts "  Decay threshold: #{target.decay_threshold_days} days"
        output.puts
        output.puts "Press Enter to keep current value."
        output.puts

        # Update name
        output.print "Enter new name [#{target.name}]: "
        output.flush
        name_input = input.gets.try(&.strip) || ""
        new_name = name_input.empty? ? target.name : name_input

        # Update tracked status
        output.print "Track this target? (y/n) [#{target.is_tracked ? "y" : "n"}]: "
        output.flush
        tracked_input = input.gets.try(&.strip.downcase) || ""
        new_is_tracked = if tracked_input.empty?
                           target.is_tracked
                         else
                           tracked_input == "y"
                         end

        # Update decay threshold
        output.print "Decay threshold [#{target.decay_threshold_days}]: "
        output.flush
        threshold_input = input.gets.try(&.strip) || ""
        new_decay_days = target.decay_threshold_days

        unless threshold_input.empty?
          loop do
            begin
              new_decay_days = threshold_input.to_i
              if new_decay_days <= 0
                output.puts "Decay threshold must be greater than 0."
                output.print "Enter decay threshold [#{target.decay_threshold_days}]: "
                output.flush
                threshold_input = input.gets.try(&.strip) || ""
                next if !threshold_input.empty?
                new_decay_days = target.decay_threshold_days
              end
              break
            rescue ArgumentError
              output.puts "Invalid number."
              output.print "Enter decay threshold [#{target.decay_threshold_days}]: "
              output.flush
              threshold_input = input.gets.try(&.strip) || ""
              next if !threshold_input.empty?
              new_decay_days = target.decay_threshold_days
              break
            end
          end
        end

        # Update the target
        target.update(
          name: new_name,
          is_tracked: new_is_tracked,
          decay_threshold_days: new_decay_days
        )

        output.puts
        output.puts "Target updated successfully!"
        output.puts "  Name: #{new_name}"
        output.puts "  Tracked: #{new_is_tracked ? "Yes" : "No"}"
        output.puts "  Decay threshold: #{new_decay_days} days"
      end
    end
  end
end
