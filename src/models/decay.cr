module Skrong
  module Models
    module Decay
      alias DecayResult = NamedTuple(
        target: Target,
        days_since: Int32,
        status: Symbol,
        last_hit_date: Time?,
        last_movement_name: String?
      )

      # Calculates decay status for a single target
      def self.calculate_for_target(target : Target, today : Time = Time.local, rpe_threshold : Int32 = 5) : DecayResult?
        db = DB::Connection.instance

        # Query to find the most recent qualifying set for this target
        query = <<-SQL
          SELECT
            sessions.date,
            movements.name
          FROM sets
          JOIN sessions ON sets.session_id = sessions.id
          JOIN movements ON sets.movement_id = movements.id
          JOIN movement_targets ON movements.id = movement_targets.movement_id
          WHERE movement_targets.target_id = ?
            AND sets.rpe >= ?
          ORDER BY sessions.date DESC
          LIMIT 1
        SQL

        result = db.query_one?(query, target.id, rpe_threshold, as: {String, String})

        return nil unless result

        last_hit_date_str = result[0]
        last_movement_name = result[1]

        last_hit_date = Time.parse(last_hit_date_str, "%Y-%m-%d", Time::Location.local)

        # Calculate days since
        days_since = ((today - last_hit_date).total_days).to_i

        # Determine status based on threshold
        status = determine_status(days_since, target.decay_threshold_days)

        {
          target: target,
          days_since: days_since,
          status: status,
          last_hit_date: last_hit_date,
          last_movement_name: last_movement_name
        }
      end

      # Calculates decay for all tracked targets
      def self.calculate_all(today : Time = Time.local, rpe_threshold : Int32 = 5) : Array(DecayResult)
        targets = Target.tracked
        results = [] of DecayResult

        targets.each do |target|
          result = calculate_for_target(target, today: today, rpe_threshold: rpe_threshold)

          if result
            results << result
          else
            # Target has never been hit - add as CRIT
            results << {
              target: target,
              days_since: 999,  # Large number to indicate never hit
              status: :crit,
              last_hit_date: nil,
              last_movement_name: nil
            }
          end
        end

        # Sort by status priority: CRIT, WARN, OK
        # Then by days_since (descending - most neglected first)
        results.sort_by do |r|
          status_priority = case r[:status]
          when :crit
            0
          when :warn
            1
          when :ok
            2
          else
            3
          end

          {status_priority, -r[:days_since]}
        end
      end

      # Determines status based on days since and threshold
      private def self.determine_status(days_since : Int32, threshold : Int32) : Symbol
        if days_since <= threshold
          :ok
        elsif days_since <= threshold + 2
          :warn
        else
          :crit
        end
      end
    end
  end
end
