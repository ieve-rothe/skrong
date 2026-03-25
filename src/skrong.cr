require "./db/connection"
require "./db/migrations"
require "./models/category"
require "./models/target"
require "./models/movement"
require "./models/session"
require "./models/set"
require "./models/decay"
require "./ui/colors"
require "./ui/prompt"
require "./ui/select"
require "./ui/table"
require "./commands/init"
require "./commands/status"
require "./commands/log"
require "./commands/library"
require "./commands/summary"
require "./commands/targets"
require "./commands/seed"
require "./cli"

module Skrong
  VERSION = "0.1.0"
end

# Main entry point when run as executable
if PROGRAM_NAME.includes?("skrong")
  Skrong::CLI.run(ARGV)
end
