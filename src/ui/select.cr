module Skrong
  module UI
    module Select
      # Renders a numbered list of items
      def self.render_list(items : Array, title : String? = nil) : String
        output = String.build do |str|
          str << title << "\n" if title

          items.each_with_index do |item, index|
            str << "  #{index + 1}. #{item}\n"
          end
        end

        output
      end

      # Parses selection input and validates it's within range
      # Returns the selected number (1-indexed) or nil if invalid
      def self.parse_selection(input : String, max : Int32) : Int32?
        return nil if input.strip.empty?

        begin
          number = input.strip.to_i
          validate_selection(number, max) ? number : nil
        rescue ArgumentError
          nil
        end
      end

      # Validates that a selection number is within valid range [1, max]
      def self.validate_selection(number : Int32, max : Int32) : Bool
        number >= 1 && number <= max
      end

      # Returns the prompt text for selection
      def self.prompt_text(max : Int32) : String
        if max == 1
          "Enter 1: "
        else
          "Enter number (1-#{max}): "
        end
      end

      # Prompts user to select from a list of items
      # Returns the selected item (0-indexed in the array)
      # This is a higher-level method that combines rendering and input
      def self.prompt(items : Array(T), title : String, io : IO = STDIN, output : IO = STDOUT) : T forall T
        output.puts render_list(items, title: title)
        output.print prompt_text(items.size)
        output.flush

        loop do
          input = io.gets
          return items[0] if input.nil? # Handle EOF

          selection = parse_selection(input, items.size)

          if selection
            return items[selection - 1]  # Convert to 0-indexed
          else
            output.puts "Invalid selection. Please enter a number between 1 and #{items.size}."
            output.print prompt_text(items.size)
            output.flush
          end
        end
      end
    end
  end
end
