module Skrong
  module Commands
    module Export
      # Exports targets to a seed file
      def self.export_targets(file_path : String, output : IO = STDOUT)
        targets = Models::Target.all

        if targets.empty?
          output.puts "No targets to export."
          return
        end

        output.puts "Exporting #{targets.size} targets to #{file_path}..."
        output.puts

        content = String.build do |str|
          targets.each do |target|
            str << "- name: \"#{target.name}\"\n"
            str << "  decay_threshold_days: #{target.decay_threshold_days}\n"
          end
        end

        File.write(file_path, content)

        output.puts "=" * 60
        output.puts "#{targets.size} targets exported successfully to #{file_path}"
        output.puts "=" * 60
      end

      # Exports movements to a seed file
      def self.export_movements(file_path : String, output : IO = STDOUT)
        movements = Models::Movement.all

        if movements.empty?
          output.puts "No movements to export."
          return
        end

        output.puts "Exporting #{movements.size} movements to #{file_path}..."
        output.puts

        # Group movements by category
        categories = Models::Category.all
        category_map = {} of Int64 => String
        categories.each { |cat| category_map[cat.id] = cat.name }

        # Build content grouped by category
        content = String.build do |str|
          categories.each do |category|
            category_movements = movements.select { |m| m.category_id == category.id }
            next if category_movements.empty?

            # Add category header
            str << "# #{category.name.upcase}\n"

            category_movements.each do |movement|
              str << "- name: \"#{movement.name}\"\n"
              str << "  category: \"#{category.name}\"\n"

              # Get targets for this movement
              movement_targets = movement.targets

              if movement_targets.any?
                str << "  targets:\n"

                # Fetch target names
                all_targets = Models::Target.all
                target_map = {} of Int64 => String
                all_targets.each { |t| target_map[t.id] = t.name }

                movement_targets.each do |mt|
                  if target_name = target_map[mt[:target_id]]?
                    str << "    - \"#{target_name}\"\n"
                  end
                end
              end

              str << "\n"
            end
          end
        end

        File.write(file_path, content)

        output.puts "=" * 60
        output.puts "#{movements.size} movements exported successfully to #{file_path}"
        output.puts "=" * 60
      end
    end
  end
end
