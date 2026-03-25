module Skrong
  module Commands
    module Log
      # Main entry point for the logging command
      def self.run(input : IO = STDIN, output : IO = STDOUT, today : Time = Time.local)
        # Phase 1: Date selection
        session_date = prompt_date(input, output, today)

        # Create session
        session = Models::Session.create(session_date)
        set_count = 0
        movements_used = [] of String

        # Phase 2-5: Movement selection and logging loop
        loop do
          # Phase 2: Category selection
          category = select_category(input, output)

          # Phase 3: Movement selection
          movement = select_movement(input, output, category)
          movements_used << movement.name unless movements_used.includes?(movement.name)

          # Phase 4: Payload entry
          last_weight = nil
          last_reps = nil
          last_rpe = nil

          loop do
            payload = prompt_payload(input, output, movement.name, last_weight, last_reps, last_rpe)

            # Create the set
            Models::Set.create(session.id, movement.id, payload[:weight], payload[:reps], payload[:rpe])
            set_count += 1

            # Store for defaults
            last_weight = payload[:weight]
            last_reps = payload[:reps]
            last_rpe = payload[:rpe]

            output.puts "Set logged: #{payload[:weight]} x #{payload[:reps]} @ RPE #{payload[:rpe]}"
            output.puts

            # Phase 5: Sticky loop
            choice = prompt_continue(input, output, movement.name)

            case choice
            when :repeat
              next  # Continue inner loop (same movement)
            when :change
              break  # Break inner loop (select new movement)
            when :done
              # Show summary and exit
              show_summary(output, session, set_count, movements_used)
              return
            end
          end
        end
      end

      # Phase 1: Date selection
      private def self.prompt_date(input : IO, output : IO, today : Time) : Time
        output.print "Log for today (#{today.to_s("%Y-%m-%d")})? (y/n): "
        output.flush

        response = input.gets.try(&.strip.downcase)

        if response == "y"
          return today
        else
          loop do
            output.print "Enter date (YYYY-MM-DD): "
            output.flush

            date_input = input.gets.try(&.strip) || ""

            begin
              return UI::Prompt.parse_date(date_input)
            rescue e : UI::Prompt::ParseError
              output.puts "Invalid date format. Please use YYYY-MM-DD."
            end
          end
        end
      end

      # Phase 2: Category selection
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

      # Phase 3: Movement selection
      private def self.select_movement(input : IO, output : IO, category : Models::Category) : Models::Movement
        movements = Models::Movement.find_by_category(category.id)

        if movements.empty?
          output.puts "No movements found for #{category.name}."
          output.puts "Please add movements using 'skrong library add'."
          exit(1)
        end

        output.puts "#{category.name} Movements:"
        movements.each_with_index do |mov, index|
          output.puts "  #{index + 1}. #{mov.name}"
        end
        output.puts

        loop do
          output.print "Enter number (1-#{movements.size}): "
          output.flush

          selection_input = input.gets.try(&.strip) || ""
          selection = UI::Select.parse_selection(selection_input, movements.size)

          if selection
            return movements[selection - 1]
          else
            output.puts "Invalid selection. Please enter a number between 1 and #{movements.size}."
          end
        end
      end

      # Phase 4: Payload entry
      private def self.prompt_payload(input : IO, output : IO, movement_name : String,
                                     last_weight : Float64?, last_reps : Int32?, last_rpe : Int32?) : NamedTuple(weight: Float64, reps: Int32, rpe: Int32)
        output.puts "[#{movement_name}]"

        if last_weight && last_reps && last_rpe
          output.puts "Previous: #{last_weight} #{last_reps} #{last_rpe}"
          output.print "Enter (↵ to repeat, or new values): "
        else
          output.print "Enter: weight reps rpe (e.g., 185 8 7): "
        end
        output.flush

        loop do
          payload_input = input.gets.try(&.strip) || ""

          # If empty and we have defaults, use them
          if payload_input.empty? && last_weight && last_reps && last_rpe
            return {weight: last_weight, reps: last_reps, rpe: last_rpe}
          end

          begin
            return UI::Prompt.parse_payload(payload_input)
          rescue e : UI::Prompt::ParseError
            output.puts "Invalid format: #{e.message}"
            output.puts UI::Prompt.payload_format_example
            output.print "Try again: "
            output.flush
          end
        end
      end

      # Phase 5: Sticky loop
      private def self.prompt_continue(input : IO, output : IO, movement_name : String) : Symbol
        output.puts "Log another set of #{movement_name}? (y/n/c)"
        output.puts "  y - Log another set"
        output.puts "  n - Done, exit"
        output.puts "  c - Change movement"
        output.print "Choice: "
        output.flush

        loop do
          choice = input.gets.try(&.strip.downcase) || ""

          case choice
          when "y"
            return :repeat
          when "n"
            return :done
          when "c"
            return :change
          else
            output.print "Invalid choice. Enter y, n, or c: "
            output.flush
          end
        end
      end

      # Display session summary
      private def self.show_summary(output : IO, session : Models::Session, set_count : Int32, movements_used : Array(String))
        output.puts
        output.puts "=" * 60
        output.puts "Session logged for #{session.date.to_s("%Y-%m-%d")}!"
        output.puts "  - #{set_count} sets logged"
        output.puts "  - #{movements_used.size} movements"
        output.puts "=" * 60
      end
    end
  end
end
