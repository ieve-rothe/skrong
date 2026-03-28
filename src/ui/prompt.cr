module Skrong
  module UI
    module Prompt
      # Custom exception for parsing errors
      class ParseError < Exception
      end

      # Parses space-delimited payload: "weight reps rpe"
      # Returns a NamedTuple with weight (Float64), reps (Int32), rpe (Int32)
      def self.parse_payload(input : String) : NamedTuple(weight: Float64, reps: Int32, rpe: Int32)
        parts = input.strip.split(/\s+/)

        raise ParseError.new("Invalid format. Expected: weight reps rpe (e.g., 40 15 8)") if parts.size != 3

        # Parse weight
        weight = begin
          parts[0].to_f
        rescue ArgumentError
          raise ParseError.new("Weight must be a positive number")
        end

        raise ParseError.new("Weight must be a positive number") if weight <= 0

        # Parse reps
        reps = begin
          # Check if it's a valid integer (no decimal point)
          if parts[1].includes?(".")
            raise ParseError.new("Reps must be a positive integer")
          end
          parts[1].to_i
        rescue ArgumentError
          raise ParseError.new("Reps must be a positive integer")
        end

        raise ParseError.new("Reps must be a positive integer") if reps <= 0

        # Parse RPE
        rpe = begin
          # Check if it's a valid integer (no decimal point)
          if parts[2].includes?(".")
            raise ParseError.new("RPE must be an integer between 1 and 10")
          end
          parts[2].to_i
        rescue ArgumentError
          raise ParseError.new("RPE must be an integer between 1 and 10")
        end

        raise ParseError.new("RPE must be an integer between 1 and 10") if rpe < 1 || rpe > 10

        {weight: weight, reps: reps, rpe: rpe}
      end

      # Parses date string in YYYY-MM-DD format
      # Returns a Time object
      def self.parse_date(input : String) : Time
        raise ParseError.new("Invalid date format. Expected: YYYY-MM-DD") if input.strip.empty?

        # Check basic format
        unless input.strip.match(/^\d{4}-\d{2}-\d{2}$/)
          raise ParseError.new("Invalid date format. Expected: YYYY-MM-DD")
        end

        begin
          Time.parse(input.strip, "%Y-%m-%d", Time::Location.local)
        rescue Time::Format::Error | ArgumentError
          raise ParseError.new("Invalid date. Please use YYYY-MM-DD format")
        end
      end

      # Validates payload format without parsing
      def self.validate_payload_format(input : String) : Bool
        begin
          parse_payload(input)
          true
        rescue ParseError
          false
        end
      end

      # Returns format example string
      def self.payload_format_example : String
        "Format: weight reps rpe (e.g., 40 15 8)\n" +
        "  weight: positive number (decimal allowed)\n" +
        "  reps:   positive integer\n" +
        "  rpe:    integer from 1 to 10"
      end

      # Parses space-delimited endurance payload: "distance duration rpe"
      # Duration format: MM:SS or HH:MM:SS
      # Returns a NamedTuple with distance (Float64), duration_seconds (Int32), rpe (Int32)
      def self.parse_endurance_payload(input : String) : NamedTuple(distance: Float64, duration_seconds: Int32, rpe: Int32)
        parts = input.strip.split(/\s+/)

        raise ParseError.new("Invalid format. Expected: distance duration rpe (e.g., 3.1 24:30 7)") if parts.size != 3

        # Parse distance
        distance = begin
          parts[0].to_f
        rescue ArgumentError
          raise ParseError.new("Distance must be a positive number")
        end

        raise ParseError.new("Distance must be a positive number") if distance <= 0

        # Parse duration (MM:SS or HH:MM:SS format)
        duration_seconds = parse_duration(parts[1])

        # Parse RPE
        rpe = begin
          if parts[2].includes?(".")
            raise ParseError.new("RPE must be an integer between 1 and 10")
          end
          parts[2].to_i
        rescue ArgumentError
          raise ParseError.new("RPE must be an integer between 1 and 10")
        end

        raise ParseError.new("RPE must be an integer between 1 and 10") if rpe < 1 || rpe > 10

        {distance: distance, duration_seconds: duration_seconds, rpe: rpe}
      end

      # Parse duration string (MM:SS or HH:MM:SS) to seconds
      private def self.parse_duration(duration_str : String) : Int32
        parts = duration_str.split(":")

        unless parts.size == 2 || parts.size == 3
          raise ParseError.new("Duration must be in MM:SS or HH:MM:SS format (e.g., 24:30 or 1:24:30)")
        end

        begin
          if parts.size == 2
            # MM:SS format
            minutes = parts[0].to_i
            seconds = parts[1].to_i
            raise ParseError.new("Invalid duration values") if minutes < 0 || seconds < 0 || seconds >= 60
            minutes * 60 + seconds
          else
            # HH:MM:SS format
            hours = parts[0].to_i
            minutes = parts[1].to_i
            seconds = parts[2].to_i
            raise ParseError.new("Invalid duration values") if hours < 0 || minutes < 0 || minutes >= 60 || seconds < 0 || seconds >= 60
            hours * 3600 + minutes * 60 + seconds
          end
        rescue ArgumentError
          raise ParseError.new("Duration must be in MM:SS or HH:MM:SS format (e.g., 24:30 or 1:24:30)")
        end
      end

      # Unified payload parser that branches based on activity type
      # Returns a NamedTuple with all fields (nullable for type-specific fields)
      def self.parse_set_payload(activity_type : String, input : String) : NamedTuple(
        weight: Float64?,
        reps: Int32?,
        distance: Float64?,
        duration_seconds: Int32?,
        rpe: Int32
      )
        if activity_type == "endurance"
          endurance = parse_endurance_payload(input)
          {
            weight:           nil,
            reps:             nil,
            distance:         endurance[:distance],
            duration_seconds: endurance[:duration_seconds],
            rpe:              endurance[:rpe],
          }
        else
          # Default to strength
          strength = parse_payload(input)
          {
            weight:           strength[:weight],
            reps:             strength[:reps],
            distance:         nil,
            duration_seconds: nil,
            rpe:              strength[:rpe],
          }
        end
      end

      # Returns endurance format example string
      def self.endurance_format_example : String
        "Format: distance duration rpe (e.g., 3.1 24:30 7)\n" +
        "  distance: positive number (miles)\n" +
        "  duration: MM:SS or HH:MM:SS\n" +
        "  rpe:      integer from 1 to 10"
      end
    end
  end
end
