module Skrong
  module UI
    module Colors
      # ANSI color codes
      GREEN  = "\e[32m"
      YELLOW = "\e[33m"
      RED    = "\e[31m"
      BOLD   = "\e[1m"
      RESET  = "\e[0m"

      # Wraps text in green color
      def self.green(text : String) : String
        "#{GREEN}#{text}#{RESET}"
      end

      # Wraps text in yellow color
      def self.yellow(text : String) : String
        "#{YELLOW}#{text}#{RESET}"
      end

      # Wraps text in red color
      def self.red(text : String) : String
        "#{RED}#{text}#{RESET}"
      end

      # Wraps text in bold formatting
      def self.bold(text : String) : String
        "#{BOLD}#{text}#{RESET}"
      end

      # Returns the reset code
      def self.reset : String
        RESET
      end

      # Colorizes text based on status symbol
      def self.colorize(text : String, status : Symbol) : String
        case status
        when :ok
          green(text)
        when :warn
          yellow(text)
        when :crit
          red(text)
        else
          text
        end
      end
    end
  end
end
