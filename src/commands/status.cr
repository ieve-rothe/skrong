module Skrong
  module Commands
    module Status
      # Displays the status report showing decay for all tracked targets
      def self.run(output : IO = STDOUT, today : Time = Time.local)
        # Calculate decay for all tracked targets
        decay_results = Models::Decay.calculate_all(today: today)

        # Convert to table rows
        rows = decay_results.map do |result|
          UI::Table::StatusRow.new(
            target_name: result[:target].name,
            last_hit_date: format_date(result[:last_hit_date]),
            days_ago: result[:days_since],
            status: result[:status],
            last_movement: result[:last_movement_name] || "--"
          )
        end

        # Render and output the table
        output.puts UI::Table.render_status(rows)
      end

      # Formats a date as "MMM DD" or "--" if nil
      private def self.format_date(date : Time?) : String
        return "--" unless date
        date.to_s("%b %-d")
      end
    end
  end
end
