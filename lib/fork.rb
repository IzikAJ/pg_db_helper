#!/usr/bin/env ruby
require_relative 'db_helper'

class DbFork < DbHelper

  def self.run(args=[])
    options = {
      relative: false,
      branch: :dev
    }
    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: .. fork [options]"
      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-b", "--branch [dev|test|stag|prod|all]", "Set branch for fork, default: development.") do |arg|
        arg = arg.downcase.to_sym
        options[:branch] = arg if [:dev, :test, :prod, :stag, :all].include?(arg)
      end

      opts.on("-n [new name]", "--name [new name]", "Set new database name.") do |arg|
        options[:name] = arg.split('.')[0]
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)
    get_configs()
    fork!(options)

    # pp options
  end
end
# DbDump.run(ARGV)
