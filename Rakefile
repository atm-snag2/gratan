require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')
task :default => :spec_all

suffixes = %w(56 57)
task :spec_all => suffixes.map { |s| "spec#{s}" }

suffixes.each do |suffix|
  overwrite_host = ENV['MYSQL_HOST'].to_s.empty?
  task "spec#{suffix}" do
    if overwrite_host
      ENV['MYSQL_HOST'] = "mysql#{suffix}"
    end
    ENV['MYSQL57'] = (suffix == '57' ? 1 : 0).to_s
    Rake::Task['spec'].execute
  end
end
