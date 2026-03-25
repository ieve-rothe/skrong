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
    end
  end
end
