$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "queight"
require "dotenv"
require "json"

def message(obj)
  JSON.dump(obj)
end

require "queight_test_helper"

Dotenv.load(".env.local")
Dotenv.load
