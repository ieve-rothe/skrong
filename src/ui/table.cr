module Skrong
  module UI
    module Table
      # Represents a row in the status table
      struct StatusRow
        property target_name : String
        property last_hit_date : String
        property days_ago : Int32
        property status : Symbol
        property last_movement : String

        def initialize(@target_name : String, @last_hit_date : String, @days_ago : Int32,
                       @status : Symbol, @last_movement : String)
        end
      end

      # Renders the status report table
      def self.render_status(rows : Array(StatusRow)) : String
        output = String.build do |str|
          # Title
          str << "\n"
          str << "SYSTEM STATUS: TARGET MUSCLE GROUPS\n"
          str << "=" * 75 << "\n"

          # Headers
          str << "%-22s %-13s %-11s %-9s %s\n" % ["TARGET", "LAST HIT", "DAYS AGO", "STATUS", "LAST MOVEMENT"]
          str << "-" * 75 << "\n"

          if rows.empty?
            str << "No tracked targets found. Run 'skrong library add' to add movements.\n"
          else
            # Data rows
            rows.each do |row|
              status_text = format_status(row.status)
              str << "%-22s %-13s %-11s %-9s %s\n" % [
                row.target_name,
                row.last_hit_date,
                row.days_ago.to_s,
                status_text,
                row.last_movement
              ]
            end
          end

          str << "=" * 75 << "\n"
        end

        output
      end

      # Formats the status with color
      private def self.format_status(status : Symbol) : String
        case status
        when :ok
          Colors.green("[OK]")
        when :warn
          Colors.yellow("[WARN]")
        when :crit
          Colors.red("[CRIT]")
        else
          "[UNKNOWN]"
        end
      end
    end
  end
end
