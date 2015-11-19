spec = Gem::Specification.new do |s|
  s.name         = "pg_db_helper"
  s.version      = "0.1"
  s.platform     = Gem::Platform::RUBY
  s.licenses    = ['MIT']
  s.authors      = "Izik AJ"
  s.email        = "izikaj@gmail.com"
  s.homepage     = "https://github.com/IzikAJ/pg_db_helper"
  s.summary      = "Just a simple Postgre database tool."
  s.description  = "Easy dump and load PostgreSQL database."
  s.files        = Dir["*.sample", "README.mkd", "LICENSE", "bin/*", "lib/*"]
  s.require_path = "lib"

  s.executables += %w(izi_load izi_dump izi_fork)

  # s.add_runtime_dependency "rack", [">= 1.1.0"]
end