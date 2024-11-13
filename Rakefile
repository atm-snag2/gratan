require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')
task :default => :spec_all

suffixes = %w(5_6 5_7)
task :spec_all => suffixes.map { |s| "spec#{s}" }

suffixes.each do |suffix|
  overwrite_host = ENV['MYSQL_HOST'].to_s.empty?
  task "spec#{suffix}" do
    if overwrite_host
      ENV['MYSQL_HOST'] = "mysql#{suffix}"
    end
    ENV['MYSQL5_7'] = (suffix == '5_7' ? 1 : 0).to_s
    Rake::Task['spec'].execute
  end
end
