require 'rubygems'
require 'fileutils'
require 'optparse'
require 'yaml'
require 'pp'
require_relative 'config_worker'

class DbHelper
  def self.get_configs()
    @working_dir = Dir.pwd
    @sysdir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    unless File.exists?(File.join(@sysdir, 'config.yml'))
      p "No config file. Creating default one."
      FileUtils.cp(File.join(@sysdir, 'config.yml.sample'), File.join(@sysdir, 'config.yml'))
      p "Please correct your config file at:"
      p "#{File.join(@sysdir, 'config.yml')}"
    end

    @config = get_hash_file File.join(@sysdir, 'config.yml')

    @db_yml_file = @config[:db_yml_file]
    @db_sample_file = @config[:db_sample_file]
    @dump_store = @config[:dump_store]

    @db_config = get_hash_file File.join(@working_dir, @db_yml_file)
    # pp @config
    # pp @db_config
  end

  def self.save_db_config!()
    put_hash_file File.join(@working_dir, @db_yml_file), @db_config
  end

  def self.dump!(options={})
    @db_config.keys.each do |env|
      if ((options[:branch]==:all) || env.to_s.start_with?(options[:branch].to_s))
        param = @db_config[env]
        dumpname = options[:file]
        dumpname = File.join([@dump_store, dumpname]) unless options[:relative]
        p "dump <#{env}> to file: #{dumpname}"
        # pp param
        system "
          PGPASSWORD='#{param[:password]}'
          pg_dump -U #{param[:username]} -h #{param[:host]} #{param[:database]} > #{dumpname}
          "
      end
    end
  end

  def self.fork!(options={})
    dumps = {}
    @db_config.keys.each do |env|
      if ((options[:branch]==:all) || env.to_s.start_with?(options[:branch].to_s))
        param = @db_config[env]
        timestamp = Time.now.strftime('%Y%m%dT%H%M%S%z')
        dumps[env] = File.join([@dump_store, "#{param[:database]}_#{timestamp}.sql"])
        p "dump <#{env}> to file: #{dumps[env]}"
        # pp param
        system "
          PGPASSWORD='#{param[:password]}'
          pg_dump -U #{param[:username]} -h #{param[:host]} #{param[:database]} > #{dumps[env]}
          "
        new_db_name = options[:name] + param[:database].gsub(/.+?(_db)?(_test)?(_db)?/i, '\1\2\3')
        @db_config[env][:database] = new_db_name

      end
    end

    p "All backups created!"
    save_db_config!

    @db_config.keys.each do |env|
      if ((options[:branch]==:all) || env.to_s.start_with?(options[:branch].to_s))
        param = @db_config[env]
        p "load <#{env}> from file: #{dumps[env]}"
        # pp param
        system "RAILS_ENV=#{env} bundle exec rake db:drop"
        system "RAILS_ENV=#{env} bundle exec rake db:create"
        system "RAILS_ENV=#{env} bundle exec rake db:migrate"
        system "
          PGPASSWORD='#{param[:password]}'
          psql -U #{param[:username]} -h #{param[:host]} #{param[:database]} < #{dumps[env]}
          "
      end
    end    
  end

  def self.load!(options={})
    @db_config.keys.each do |env|
      if ((options[:branch]==:all) || env.to_s.start_with?(options[:branch].to_s))
        param = @db_config[env]
        dumpname = options[:file]
        dumpname = File.join([@dump_store, dumpname]) unless options[:relative]
        p "load <#{env}> from file: #{dumpname}"
        # pp param
        if options[:clean]
          system "bundle exec rake db:drop"
          system "bundle exec rake db:create"
          system "bundle exec rake db:migrate"
        end
        system "
          PGPASSWORD='#{param[:password]}'
          psql -U #{param[:username]} -h #{param[:host]} #{param[:database]} < #{dumpname}
          "
      end
    end
  end

end
# @options = Parser.new do |p|
#   p.banner = "This is a db helper, for usage see below"
#   p.version = "db helper 0.0 alpha"
#   # p.option :severity, "set severity", :default => 4, :value_in_set => [4,5,6,7,8]
#   # p.option :verbose, "enable verbose output"
#   # p.option :mutation, "set mutation", :default => "MightyMutation", :value_matches => /Mutation/
#   # p.option :plus_selection, "use plus-selection if set", :default => true
#   # p.option :selection, "selection used", :default => "BestSelection", :short => "l"
#   # p.option :chance, "set mutation chance", :default => 0.8, :value_satisfies => lambda {|x| x >= 0.0 && x <= 1.0}
#   p.option :dump, "dump app DB to dumpstore folder", default: ''
#   p.option :load, "load DB from dump file stored in dumpstore folder", default: ''
#   p.option :migrate, "backup DB, drop, migrate and restore it from backup file stored in dumpstore folder (only development)", default: ''
#   p.option :fork, "forks DB from current and dump it", short: 'F', default: ''
#   p.option :apply, "apply DB from dump", default: ''
#   p.option :file, "name of dump DB from dumpstore folder", default: ''
#   p.option :bundle, "bundle update & push to git", default: ''
#   p.option :api, "sattelite api for bundle update", default: ''
#   p.option :gem, "gem name for bundle update", default: ''
# end.process!

# def get_dumpname(db_name = nil, env)
#   log @options
#   log @options[:file]
#   if @options[:file]
#     File.join(@dump_store, @options[:file])
#   else
#     File.join(@dump_store, "dump_#{db_name}_#{env}.db")
#   end
# end

# def current_time
#   Time.now.getlocal.strftime('%H:%M:%S')
# end

# def log(st)
#   STDOUT << "#{current_time} #{st}\n"
# end

# def pparams(param)
#   (param.map{|k, v| "#{k}: #{v}, " unless k.to_sym==:password}.join()).chomp(', ').gsub(", ", "\n#{' '*5}- ")
# end

# def keys_to_sym src
#   dst = {}
#   src.each do |k, v|
#     dst[k.to_sym] = v.is_a?(Hash) ? keys_to_sym(v) : v
#   end
#   dst
# end
# def keys_to_str src
#   dst = {}
#   src.each do |k, v|
#     dst[k.to_s] = v.is_a?(Hash) ? keys_to_str(v) : v
#   end
#   dst
# end

# def get_db_prop filename
#   if File.exist?(filename)
#     keys_to_sym YAML.load_file(filename)
#   else
#     @db_yml_sample_hash
#   end
# end

# def put_db_prop filename, props
#   File.open(filename, 'w') do |f|
#     f.write((keys_to_str props).to_yaml)
#   end
# end

# def dump_db(param = {}, dumpname)
#   # dumpname = get_dumpname(param[:database], environment)
#   param = @default_params.merge(param)
#   log "dump db: \n#{pparams(param)} \nto >>> #{dumpname}"

#   system "PGPASSFILE=<(echo #{param[:host]}:#{param[:port]}:#{param[:database]}:#{param[:username]}:#{param[:password]})
#     pg_dump -U #{param[:username]} -h #{param[:host]} #{param[:database]} > #{dumpname}"

#   log "dump finished"
# end

# def load_db(param = {}, dumpname)
#   param = @default_params.merge(param)
#   log "load db: from >>> #{dumpname}\n - With params:\n#{pparams(param)}"

#   system "PGPASSFILE=<(echo #{param[:host]}:#{param[:port]}:#{param[:database]}:#{param[:username]}:#{param[:password]})
#     psql -U #{param[:username]} -h #{param[:host]} #{param[:database]} < #{dumpname}"

#   log "load finished"
# end

# def load_prop(env=:development)
#   all_prop = get_db_prop @db_yml_file
#   all_prop[env]
# end

# def reset_migrate
#   param = load_prop
#   dumpname = File.join(@dump_store, "dump_#{param[:database]}_t#{Time.now.to_i}.db")
#   dump_db param, dumpname
#   system 'rake db:drop'
#   log 'db dropped'
#   system 'rake db:create'
#   log 'new db created'
#   system 'rake db:migrate'
#   log 'db migrated'
#   load_db param, dumpname
#   log 'stored db dump removed'
#   system "rm #{dumpname}"
#   log 'stored db dump removed'
# end

# def fork_db database
#   # new_prop, old_prop = change_db_config("database"=> "#{@options[:fork]}")
#   full_params = get_db_prop @db_yml_file

#   dumpnames = {}
#   full_params.each do |env, param|
#     if env.to_s =~ /dev/
#       dumpname = File.join(@dump_store, "dump_#{param[:database]}_t#{Time.now.to_i}.db")
#       dumpnames[env] = dumpname
#       dump_db param, dumpname
#       full_params[env][:database] = database + full_params[env][:database].gsub(/.+?(_db)?(_test)?(_db)?/i, '\1\2\3')
#     end
#   end

#   put_db_prop @db_yml_file, full_params

#   full_params.each do |env, param|
#     if env.to_s =~ /dev/
#       system "rake db:drop RAILS_ENV=#{env}"
#       log 'db dropped'
#       system "rake db:create RAILS_ENV=#{env}"
#       log 'new db created'
#       system "rake db:migrate RAILS_ENV=#{env}"
#       log 'db migrated'
#       load_db param, dumpnames[env]
#       log 'stored db dump removed'
#       system "rm #{dumpnames[env]}"
#       log 'stored db dump removed'
#     end
#   end
#   log 'db fork created'
# end

# def env?(prop)
#   env = %r[(^|\W)(#{prop}\w*)].match(@db_yml_sample_hash.keys().join(', '))
#   env = env[2].to_sym if env
#   env
# end

# def dump_db1(dump_store = '~/www/db/dump_')
#   log 'Dump app DB...'
#   if File.exist?(@db_yml_file)
#     props = get_db_prop @db_yml_file
#     if props.is_a?(Hash) && (props.size > 0)
#       props.each_pair do |env, param|
#         if !!(@options[:dump].index env) || !!(@options[:dump].index 'all')
#           log "environment - #{env}"
#           log "dump - '#{param['database']}' to '#{dump_store}#{param['database']}_#{env}.db'"
#           system "PGPASSFILE=<(echo #{param['host']}:#{param['port']}:#{param['database']}:#{param['username']}:#{param['password']}) pg_dump -U #{param['username']} -h #{param['host']} #{param['database']} > #{dump_store}#{param['database']}_#{env}.db"
#           # pg_dump -U dev -h localhost -W force_db > ../dump
#           # psql -U dev -h localhost -W force_db < ../dump
#         end
#       end
#       log "dump finished"
#     else
#       log 'ERROR - DB not found, please dump it by yourself!'
#     end
#   else
#     log 'ERROR - database.yml not found!'
#   end

# end

# def load_db1(dump_store = '~/www/db/dump_')
#   log 'Load DB from dump...'
#   if File.exist?(@db_yml_file)
#     props = get_db_prop @db_yml_file
#     if props.is_a?(Hash) && (props.size > 0)
#       props.each_pair do |env, param|
#         if !!(@options[:dump].index env) || !!(@options[:dump].index 'all')
#           log "environment - #{env}"
#           log "load - '#{param['database']}' from '#{dump_store}#{param['database']}_#{env}.db'"
#           if File.exist?("#{dump_store}#{param['database']}_#{env}.db")
#             system "PGPASSFILE=<(echo #{param['host']}:#{param['port']}:#{param['database']}:#{param['username']}:#{param['password']}) psql -U #{param['username']} -h #{param['host']} #{param['database']} < #{dump_store}#{param['database']}_#{env}.db"
#           else
#             log "ERROR - dump file not found, please make sure file '#{dump_store}#{param['database']}_#{env}.db' exists!"
#           end
#           # pg_dump -U dev -h localhost -W force_db > ../dump
#           # psql -U dev -h localhost -W force_db < ../dump
#         end
#       end
#       log "dump finished"
#     else
#       log 'ERROR - DB not found, please dump it by yourself!'
#     end
#   end
# end

# def sattelites apiV=nil
#   if apiV
#     Dir.glob(File.expand_path("~/www/api_v#{apiV}/*/"))
#   else
#     Dir.glob(File.expand_path('~/www/api_v*/*/'))
#   end
# end

# def bundleUpdate sats=[], gemName=nil
#   log 'Bundle update...'
#   errors = []
#   sats.each_with_index do |sat, index|
#     prefix = "cd #{sat}"
#     cmds = [
#       "git pull origin master",
#       ["bundle update", gemName].join(' '),
#       "git add Gemfile Gemfile.lock",
#       "git commit -m 'bundle update #{gemName}'",
#       "git push origin master"
#     ]
#     if system prefix
#       log "#{index}/#{sats.size} work on #{sat}"
#       cmds.each do |cmd|
#         if system [prefix, cmd].join(' && ')
#           log "#{cmd} >>> SUCCESS"
#         else
#           log "#{cmd} >>> FAILED"
#           errors << [sat, cmd]
#           log "!!!!!!!!!! FAILED #{sat}"
#           break
#         end
#       end
#     end
#   end
#   if errors.size > 0
#     log "!!!! TOTAL ERRORS: #{errors.size}"
#     errors.each_with_index do |err, index|
#       log "FAILED: #{err[1]} on #{err[0]}"
#     end
#   end
# end





# def magick
#   if @options[:dump].size > 0
#     if env = env?(@options[:dump])
#       param = load_prop env
#       dump_db param, get_dumpname(param[:database], env)
#     end
#   elsif @options[:load].size > 0
#     if env = env?(@options[:load])
#       param = load_prop env
#       load_db param, get_dumpname(param[:database], env)
#     end
#   elsif @options[:migrate].size > 0
#     reset_migrate
#   elsif @options[:fork].size > 0
#     fork_db @options[:fork]
#   elsif @options[:bundle].size > 0
#     api = (@options[:api].size) > 0 ? @options[:api] : nil
#     gemName = (@options[:gem].size > 0) ? @options[:gem] : nil
#     sats = sattelites(api)
#     bundleUpdate sats, gemName
#   end
# end

# magick()
# # dump_db() if @options[:dump]
# # load_db() if @options[:load]
# # reset_migrate() if @options[:migrate]
# # fork_db() if @options[:fork]

# # app.add_import 'some/other/file.rake'
# # app.load_rakefile

# # log db_yml_sample_hash.inspect
# # log File.exist?(@db_yml_file)
# # log File.exist?(@db_sample_file)

# # system 'rake db:drop'



