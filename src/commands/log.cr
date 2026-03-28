module Skrong
  module Commands
    module Log
      # Exception for user requesting quit
      class QuitRequested < Exception
      end

      # Exception for user requesting back navigation
      class BackRequested < Exception
      end

      # Main entry point for the logging command
      def self.run(input : IO = STDIN, output : IO = STDOUT, today : Time = Time.local)
        # Phase 1: Date selection
        session_date = prompt_date(input, output, today)

        # Create session
        session = Models::Session.create(session_date)
        set_count = 0
        movements_used = [] of String

        begin
          # Phase 2-5: Movement selection and logging loop
          loop do
            # Phase 2: Category selection
            category = select_category(input, output)

            # Phase 3: Movement selection with back support
            loop do
              begin
                movement = select_movement(input, output, category)
                movements_used << movement.name unless movements_used.includes?(movement.name)

                # Phase 4: Payload entry with back support
                # Track last values for both strength and endurance
                last_weight = nil
                last_reps = nil
                last_rpe = nil
                last_distance = nil
                last_duration_seconds = nil

                loop do
                  begin
                    payload = prompt_payload(input, output, movement.name, category.activity_type,
                      last_weight, last_reps, last_rpe, last_distance, last_duration_seconds)

                    # Create the appropriate type of set
                    if category.activity_type == "endurance"
                      Models::Set.create_endurance(session.id, movement.id,
                        payload[:distance].not_nil!, payload[:duration_seconds].not_nil!, payload[:rpe])
                      set_count += 1

                      # Store for defaults
                      last_distance = payload[:distance]
                      last_duration_seconds = payload[:duration_seconds]
                      last_rpe = payload[:rpe]

                      # Format output for endurance
                      dist = payload[:distance].not_nil!
                      dur = payload[:duration_seconds].not_nil!
                      # Create a temporary set to use formatting helpers
                      temp_set = Models::Set.new(0_i64, session.id, movement.id, nil, nil, payload[:rpe], dist, dur)
                      output.puts "Effort logged: #{dist} mi in #{temp_set.format_duration(dur)} @ RPE #{payload[:rpe]}"
                    else
                      Models::Set.create(session.id, movement.id,
                        payload[:weight].not_nil!, payload[:reps].not_nil!, payload[:rpe])
                      set_count += 1

                      # Store for defaults
                      last_weight = payload[:weight]
                      last_reps = payload[:reps]
                      last_rpe = payload[:rpe]

                      output.puts "Set logged: #{payload[:weight]} x #{payload[:reps]} @ RPE #{payload[:rpe]}"
                    end
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
                  rescue BackRequested
                    # Go back to movement selection
                    break
                  end
                end

                # If we got here normally (not via back), break to category selection
                break
              rescue BackRequested
                # Go back to category selection
                break
              end
            end
          end
        rescue QuitRequested
          # User requested quit - show summary if any sets were logged
          if set_count > 0
            show_summary(output, session, set_count, movements_used)
          else
            output.puts
            output.puts "No sets logged. Session cancelled."
          end
        end
      end

      # Phase 1: Date selection
      private def self.prompt_date(input : IO, output : IO, today : Time) : Time
        output.print "Log for today (#{today.to_s("%Y-%m-%d")})? (Y/n): "
        output.flush

        response = input.gets.try(&.strip.downcase) || "y"

        if response == "y" || response.empty?
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
        output.puts "  (q to quit)"
        output.puts

        loop do
          output.print "Enter number (1-#{categories.size}): "
          output.flush

          selection_input = input.gets.try(&.strip.downcase) || ""

          # Check for quit
          raise QuitRequested.new if selection_input == "q"

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
        output.puts "  (b to go back, q to quit)"
        output.puts

        loop do
          output.print "Enter number (1-#{movements.size}): "
          output.flush

          selection_input = input.gets.try(&.strip.downcase) || ""

          # Check for quit or back
          raise QuitRequested.new if selection_input == "q"
          raise BackRequested.new if selection_input == "b"

          selection = UI::Select.parse_selection(selection_input, movements.size)

          if selection
            return movements[selection - 1]
          else
            output.puts "Invalid selection. Please enter a number between 1 and #{movements.size}."
          end
        end
      end

      # Phase 4: Payload entry
      private def self.prompt_payload(input : IO, output : IO, movement_name : String, activity_type : String,
                                     last_weight : Float64?, last_reps : Int32?, last_rpe : Int32?,
                                     last_distance : Float64?, last_duration_seconds : Int32?) : NamedTuple(
        weight: Float64?,
        reps: Int32?,
        distance: Float64?,
        duration_seconds: Int32?,
        rpe: Int32
      )
        output.puts "[#{movement_name}]"
        output.puts "(b to go back, q to quit)"

        if activity_type == "endurance"
          # Endurance payload prompting
          if last_distance && last_duration_seconds && last_rpe
            # Format duration for display
            temp_set = Models::Set.new(0_i64, 0_i64, 0_i64, nil, nil, last_rpe, last_distance, last_duration_seconds)
            formatted_duration = temp_set.format_duration(last_duration_seconds)
            output.puts "Previous: #{last_distance} #{formatted_duration} #{last_rpe}"
            output.print "Enter (↵ to repeat, or new values): "
          else
            output.print "Enter: distance duration rpe (e.g., 3.1 24:30 7): "
          end
        else
          # Strength payload prompting
          if last_weight && last_reps && last_rpe
            output.puts "Previous: #{last_weight} #{last_reps} #{last_rpe}"
            output.print "Enter (↵ to repeat, or new values): "
          else
            output.print "Enter: weight reps rpe (e.g., 185 8 7): "
          end
        end
        output.flush

        loop do
          payload_input = input.gets.try(&.strip) || ""

          # Check for quit or back first
          raise QuitRequested.new if payload_input.downcase == "q"
          raise BackRequested.new if payload_input.downcase == "b"

          # If empty and we have defaults, use them
          if payload_input.empty?
            if activity_type == "endurance" && last_distance && last_duration_seconds && last_rpe
              return {weight: nil, reps: nil, distance: last_distance, duration_seconds: last_duration_seconds, rpe: last_rpe}
            elsif activity_type != "endurance" && last_weight && last_reps && last_rpe
              return {weight: last_weight, reps: last_reps, distance: nil, duration_seconds: nil, rpe: last_rpe}
            end
          end

          begin
            return UI::Prompt.parse_set_payload(activity_type, payload_input)
          rescue e : UI::Prompt::ParseError
            output.puts "Invalid format: #{e.message}"
            if activity_type == "endurance"
              output.puts UI::Prompt.endurance_format_example
            else
              output.puts UI::Prompt.payload_format_example
            end
            output.print "Try again: "
            output.flush
          end
        end
      end

      # Phase 5: Sticky loop
      private def self.prompt_continue(input : IO, output : IO, movement_name : String) : Symbol
        output.puts "Log another set of #{movement_name}? (y/n/c/q)"
        output.puts "  y - Log another set"
        output.puts "  n - Done, exit"
        output.puts "  c - Change movement"
        output.puts "  q - Quit (same as done)"
        output.print "Choice: "
        output.flush

        loop do
          choice = input.gets.try(&.strip.downcase) || ""

          case choice
          when "y"
            return :repeat
          when "n", "q"
            return :done
          when "c"
            return :change
          else
            output.print "Invalid choice. Enter y, n, c, or q: "
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
