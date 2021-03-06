#!/usr/bin/env ruby
require_relative 'db_helper'

class DbLoad < DbHelper

  def self.run(args=[])
    options = {
      relative: false,
      clean: false,
      reset: false,
      branch: :dev
    }
    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: .. load [options]"
      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-f", "--file [database name]", "Set output file for database dump file.") do |arg|
        options[:file] = arg
      end

      opts.on("-b", "--branch [dev|test|stag|prod|all]", "Set branch for load, default: development.") do |arg|
        arg = arg.downcase.to_sym
        options[:branch] = arg if [:dev, :test, :prod, :stag, :all].include?(arg)
      end

      opts.on("-r", "--relative", "Set relative position of database dump file, if no option - used db store folder.") do |arg|
        options[:relative] = true
      end

      opts.on("-c", "--clean", "Clean db before load (drop>create>migrate>load)") do |arg|
        options[:clean] = true
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)
    get_configs()
    load!(options)

    # pp options
  end
end

# DbLoad.run(ARGV)
