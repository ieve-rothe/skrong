require "spec"

# Set test environment to use local test database instead of production XDG path
ENV["SKRONG_ENV"] = "test"

require "../src/skrong"
