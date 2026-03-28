module Skrong
  module CLI
    # Main entry point for the CLI
    def self.run(args : Array(String), input : IO = STDIN, output : IO = STDOUT)
      # Handle empty args or help flags
      if args.empty? || args.includes?("--help") || args.includes?("-h")
        show_help(output)
        return
      end

      # Handle version flag
      if args.includes?("--version") || args.includes?("-v")
        output.puts "skrong version #{VERSION}"
        return
      end

      # Get the command
      command = args[0]

      case command
      when "init"
        Commands::Init.run(output: output)
      when "status"
        Commands::Status.run(output: output)
      when "log"
        Commands::Log.run(input: input, output: output)
      when "summary"
        handle_summary_command(args[1..]?, output: output)
      when "library"
        handle_library_command(args[1..]?, input: input, output: output)
      when "targets"
        handle_targets_command(args[1..]?, input: input, output: output)
      when "seed"
        handle_seed_command(args[1..]?, output: output)
      else
        output.puts "Unknown command: #{command}"
        output.puts "Run 'skrong --help' for usage information."
      end
    end

    # Handles summary command with optional date argument
    private def self.handle_summary_command(subargs : Array(String)?, output : IO)
      if subargs && !subargs.empty?
        date_str = subargs[0]
        begin
          date = UI::Prompt.parse_date(date_str)
          Commands::Summary.run(date: date, output: output)
        rescue e : UI::Prompt::ParseError
          output.puts "Invalid date format: #{date_str}"
          output.puts "Please use YYYY-MM-DD format (e.g., 2026-03-24)"
        end
      else
        # No date provided, use today
        Commands::Summary.run(output: output)
      end
    end

    # Handles library subcommands
    private def self.handle_library_command(subargs : Array(String)?, input : IO, output : IO)
      if subargs.nil? || subargs.empty?
        output.puts "Library command requires a subcommand."
        output.puts ""
        output.puts "Available subcommands:"
        output.puts "  library list              List all movements"
        output.puts "  library add               Add a new movement"
        output.puts "  library delete <id>       Delete a movement"
        return
      end

      subcommand = subargs[0]

      case subcommand
      when "list"
        Commands::Library.list(output: output)
      when "add"
        Commands::Library.add(input: input, output: output)
      when "delete"
        if subargs.size < 2
          output.puts "Usage: skrong library delete <movement_id>"
          return
        end

        begin
          movement_id = subargs[1].to_i64
          Commands::Library.delete(movement_id, input: input, output: output)
        rescue ArgumentError
          output.puts "Invalid movement ID: #{subargs[1]}"
        end
      else
        output.puts "Unknown library subcommand: #{subcommand}"
        output.puts "Run 'skrong library' to see available subcommands."
      end
    end

    # Handles targets subcommands
    private def self.handle_targets_command(subargs : Array(String)?, input : IO, output : IO)
      if subargs.nil? || subargs.empty?
        output.puts "Targets command requires a subcommand."
        output.puts ""
        output.puts "Available subcommands:"
        output.puts "  targets list              List all targets (muscle groups)"
        output.puts "  targets add               Add a new target"
        output.puts "  targets edit <id>         Edit a target"
        output.puts "  targets delete <id>       Delete a target"
        return
      end

      subcommand = subargs[0]

      case subcommand
      when "list"
        Commands::Targets.list(output: output)
      when "add"
        Commands::Targets.add(input: input, output: output)
      when "edit"
        if subargs.size < 2
          output.puts "Usage: skrong targets edit <target_id>"
          return
        end

        begin
          target_id = subargs[1].to_i64
          Commands::Targets.edit(target_id, input: input, output: output)
        rescue ArgumentError
          output.puts "Invalid target ID: #{subargs[1]}"
        end
      when "delete"
        if subargs.size < 2
          output.puts "Usage: skrong targets delete <target_id>"
          return
        end

        begin
          target_id = subargs[1].to_i64
          Commands::Targets.delete(target_id, input: input, output: output)
        rescue ArgumentError
          output.puts "Invalid target ID: #{subargs[1]}"
        end
      else
        output.puts "Unknown targets subcommand: #{subcommand}"
        output.puts "Run 'skrong targets' to see available subcommands."
      end
    end

    # Handles seed subcommands
    private def self.handle_seed_command(subargs : Array(String)?, output : IO)
      if subargs.nil? || subargs.empty?
        output.puts "Seed command requires a subcommand."
        output.puts ""
        output.puts "Available subcommands:"
        output.puts "  seed categories <file>    Import categories from seed file"
        output.puts "  seed targets <file>       Import targets from seed file"
        output.puts "  seed movements <file>     Import movements from seed file"
        output.puts ""
        output.puts "Examples:"
        output.puts "  skrong seed categories endurance_categories_seed.md"
        output.puts "  skrong seed targets targets_seed.md"
        output.puts "  skrong seed movements movements_seed.md"
        return
      end

      subcommand = subargs[0]

      case subcommand
      when "categories"
        if subargs.size < 2
          output.puts "Usage: skrong seed categories <file_path>"
          return
        end

        file_path = subargs[1]
        Commands::Seed.import_categories(file_path, output: output)
      when "targets"
        if subargs.size < 2
          output.puts "Usage: skrong seed targets <file_path>"
          return
        end

        file_path = subargs[1]
        Commands::Seed.import_targets(file_path, output: output)
      when "movements"
        if subargs.size < 2
          output.puts "Usage: skrong seed movements <file_path>"
          return
        end

        file_path = subargs[1]
        Commands::Seed.import_movements(file_path, output: output)
      else
        output.puts "Unknown seed subcommand: #{subcommand}"
        output.puts "Run 'skrong seed' to see available subcommands."
      end
    end

    # Shows help information
    private def self.show_help(output : IO)
      output.puts <<-HELP
      skrong - CLI Workout Tracker

      Usage:
        skrong <command> [options]

      Commands:
        init                      Initialize the database
        status                    Show training status for all muscle groups
        log                       Log a workout session (interactive)
        summary [date]            Show workout summary for a date (defaults to today)
        library list              List all movements in your library
        library add               Add a new movement to your library
        library delete <id>       Delete a movement from your library
        targets list              List all targets (muscle groups)
        targets add               Add a new target
        targets edit <id>         Edit a target
        targets delete <id>       Delete a target
        seed targets <file>       Import targets from seed file
        seed movements <file>     Import movements from seed file

      Options:
        -h, --help               Show this help message
        -v, --version            Show version information

      Examples:
        skrong init              Set up the database
        skrong status            Check which muscle groups need attention
        skrong log               Start logging a workout
        skrong summary           Show today's workout summary
        skrong summary 2026-03-20    Show summary for a specific date
        skrong library list      View all available movements
        skrong targets list      View all muscle groups
        skrong targets add       Add a custom muscle group
        skrong seed targets targets_seed.md    Bulk import targets
        skrong seed movements movements_seed.md    Bulk import movements

      For more information, visit: https://github.com/yourusername/skrong
      HELP
    end
  end
end
