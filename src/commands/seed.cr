module Skrong
  module Commands
    module Seed
      # Imports targets from a seed file
      def self.import_targets(file_path : String, output : IO = STDOUT)
        unless File.exists?(file_path)
          output.puts "File not found: #{file_path}"
          return
        end

        output.puts "Importing targets from #{file_path}..."
        output.puts

        content = File.read(file_path)
        targets_data = parse_targets_seed(content)

        imported = 0
        skipped = 0

        targets_data.each do |target_data|
          # Check if target already exists
          existing = Models::Target.all.find { |t| t.name == target_data[:name] }

          if existing
            output.puts "  ⊘ Skipped: #{target_data[:name]} (already exists)"
            skipped += 1
            next
          end

          Models::Target.create(
            target_data[:name],
            is_tracked: true,
            decay_threshold_days: target_data[:decay_threshold_days]
          )

          output.puts "  ✓ Imported: #{target_data[:name]} (#{target_data[:decay_threshold_days]} days)"
          imported += 1
        end

        output.puts
        output.puts "=" * 60
        output.puts "#{imported} targets imported successfully, #{skipped} skipped."
        output.puts "=" * 60
      end

      # Imports movements from a seed file
      def self.import_movements(file_path : String, output : IO = STDOUT)
        unless File.exists?(file_path)
          output.puts "File not found: #{file_path}"
          return
        end

        output.puts "Importing movements from #{file_path}..."
        output.puts

        content = File.read(file_path)
        movements_data = parse_movements_seed(content)

        imported = 0
        skipped = 0
        errors = 0

        movements_data.each do |movement_data|
          # Check if movement already exists
          existing = Models::Movement.all.find { |m| m.name == movement_data[:name] }

          if existing
            output.puts "  ⊘ Skipped: #{movement_data[:name]} (already exists)"
            skipped += 1
            next
          end

          # Find category
          category = Models::Category.all.find { |c| c.name == movement_data[:category] }

          unless category
            output.puts "  ✗ Error: #{movement_data[:name]} - Category not found: #{movement_data[:category]}"
            errors += 1
            next
          end

          # Create movement
          movement = Models::Movement.create(movement_data[:name], category.id)

          # Add targets
          movement_data[:targets].each do |target_name|
            target = Models::Target.all.find { |t| t.name == target_name }

            if target
              movement.add_target(target.id, is_primary: true)
            else
              output.puts "  ⚠ Warning: Target not found for #{movement_data[:name]}: #{target_name}"
            end
          end

          output.puts "  ✓ Imported: #{movement_data[:name]} (#{movement_data[:category]})"
          imported += 1
        end

        output.puts
        output.puts "=" * 60
        output.puts "#{imported} movements imported successfully, #{skipped} skipped, #{errors} errors."
        output.puts "=" * 60
      end

      # Parses targets seed file content
      private def self.parse_targets_seed(content : String) : Array(NamedTuple(name: String, decay_threshold_days: Int32))
        targets = [] of NamedTuple(name: String, decay_threshold_days: Int32)
        current_target : NamedTuple(name: String, decay_threshold_days: Int32)? = nil
        current_name : String? = nil

        content.lines.each do |line|
          line = line.strip

          # Skip empty lines and section headers
          next if line.empty?
          next if line.starts_with?("#") && !line.includes?("- name:")

          # Parse name line
          if line.starts_with?("- name:")
            # Save previous target if exists
            if current_name
              targets << {name: current_name, decay_threshold_days: 5}
            end

            # Extract name, removing quotes and parenthetical notes
            name_match = line.match(/- name:\s*"([^"]+)"/)
            if name_match
              current_name = name_match[1].strip
            end
          # Parse decay_threshold_days line
          elsif line.includes?("decay_threshold_days:")
            if current_name
              # Extract decay days, removing inline comments
              decay_match = line.match(/decay_threshold_days:\s*(\d+)/)
              if decay_match
                decay_days = decay_match[1].to_i
                targets << {name: current_name, decay_threshold_days: decay_days}
                current_name = nil
              end
            end
          end
        end

        # Save last target if it didn't have decay_threshold_days
        if current_name
          targets << {name: current_name, decay_threshold_days: 5}
        end

        targets
      end

      # Parses movements seed file content
      private def self.parse_movements_seed(content : String) : Array(NamedTuple(name: String, category: String, targets: Array(String)))
        movements = [] of NamedTuple(name: String, category: String, targets: Array(String))
        current_name : String? = nil
        current_category : String? = nil
        current_targets = [] of String
        in_targets_section = false

        content.lines.each do |line|
          line = line.strip

          # Skip empty lines and pure comment lines
          next if line.empty?
          next if line.starts_with?("#") && !line.includes?("- name:")

          # Parse name line
          if line.starts_with?("- name:")
            # Save previous movement if exists
            if current_name && current_category
              movements << {name: current_name, category: current_category, targets: current_targets}
            end

            # Reset state
            current_targets = [] of String
            current_category = nil
            in_targets_section = false

            # Extract name
            name_match = line.match(/- name:\s*"([^"]+)"/)
            if name_match
              current_name = name_match[1].strip
            end
          # Parse category line
          elsif line.includes?("category:")
            category_match = line.match(/category:\s*"([^"]+)"/)
            if category_match
              current_category = category_match[1].strip
            end
          # Parse targets section
          elsif line.includes?("targets:")
            in_targets_section = true
          elsif in_targets_section && line.starts_with?("- ")
            # Extract target name
            target_match = line.match(/-\s*"([^"]+)"/)
            if target_match
              current_targets << target_match[1].strip
            end
          end
        end

        # Save last movement
        if current_name && current_category
          movements << {name: current_name, category: current_category, targets: current_targets}
        end

        movements
      end
    end
  end
end
