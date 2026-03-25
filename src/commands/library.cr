module Skrong
  module Commands
    module Library
      # Lists all movements grouped by category
      def self.list(output : IO = STDOUT)
        movements = Models::Movement.all

        if movements.empty?
          output.puts "No movements in your library."
          output.puts "Run 'skrong library add' to add movements."
          return
        end

        output.puts
        output.puts "MOVEMENT LIBRARY"
        output.puts "=" * 70
        output.puts

        # Group by category
        categories = Models::Category.all
        categories.each do |category|
          category_movements = Models::Movement.find_by_category(category.id)

          next if category_movements.empty?

          output.puts UI::Colors.bold("#{category.name}:")
          category_movements.each do |movement|
            targets = movement.targets
            target_names = targets.map do |t|
              target = Models::Target.find(t[:target_id])
              target ? target.name : "Unknown"
            end

            output.print "  [#{movement.id}] #{movement.name}"
            unless target_names.empty?
              output.print " → #{target_names.join(", ")}"
            end
            output.puts
          end
          output.puts
        end

        output.puts "=" * 70
      end

      # Adds a new movement to the library
      def self.add(input : IO = STDIN, output : IO = STDOUT)
        output.puts "Add New Movement"
        output.puts "=" * 40
        output.puts

        # Select category
        category = select_category(input, output)

        # Enter movement name
        output.print "Enter movement name: "
        output.flush
        name = input.gets.try(&.strip) || ""

        if name.empty?
          output.puts "Movement name cannot be empty."
          return
        end

        # Create the movement
        movement = Models::Movement.create(name, category.id)

        # Add targets
        output.puts
        output.puts "Add targets to this movement (primary muscle groups)."
        output.puts "Type 'done' when finished."
        output.puts

        targets = Models::Target.all
        if targets.empty?
          output.puts "No targets available. Movement created without targets."
        else
          loop do
            output.puts "Available targets:"
            targets.each_with_index do |target, index|
              output.puts "  #{index + 1}. #{target.name}"
            end
            output.puts

            output.print "Select target (1-#{targets.size}) or 'done': "
            output.flush

            selection_input = input.gets.try(&.strip.downcase) || ""

            break if selection_input == "done"

            selection = UI::Select.parse_selection(selection_input, targets.size)

            if selection
              target = targets[selection - 1]
              movement.add_target(target.id, is_primary: true)
              output.puts "Added target: #{target.name}"
              output.puts
            else
              output.puts "Invalid selection."
            end
          end
        end

        output.puts
        output.puts "Movement added successfully!"
        output.puts "  Name: #{movement.name}"
        output.puts "  Category: #{category.name}"
        output.puts "  ID: #{movement.id}"
      end

      # Deletes a movement from the library
      def self.delete(movement_id : Int64, input : IO = STDIN, output : IO = STDOUT)
        movement = Models::Movement.find(movement_id)

        unless movement
          output.puts "Movement with ID #{movement_id} not found."
          return
        end

        output.puts "Delete Movement"
        output.puts "=" * 40
        output.puts "Movement: #{movement.name}"
        output.puts "ID: #{movement.id}"
        output.puts

        output.print "Are you sure you want to delete this movement? (y/n): "
        output.flush

        confirmation = input.gets.try(&.strip.downcase) || ""

        if confirmation == "y"
          # Delete the movement
          db = DB::Connection.instance

          # Delete associated movement_targets first
          db.exec("DELETE FROM movement_targets WHERE movement_id = ?", movement_id)

          # Delete the movement
          db.exec("DELETE FROM movements WHERE id = ?", movement_id)

          output.puts "Movement deleted successfully."
        else
          output.puts "Deletion cancelled."
        end
      end

      # Helper method to select a category
      private def self.select_category(input : IO, output : IO) : Models::Category
        categories = Models::Category.all

        output.puts "Select category:"
        categories.each_with_index do |cat, index|
          output.puts "  #{index + 1}. #{cat.name}"
        end
        output.puts

        loop do
          output.print "Enter number (1-#{categories.size}): "
          output.flush

          selection_input = input.gets.try(&.strip) || ""
          selection = UI::Select.parse_selection(selection_input, categories.size)

          if selection
            return categories[selection - 1]
          else
            output.puts "Invalid selection. Please enter a number between 1 and #{categories.size}."
          end
        end
      end
    end
  end
end
