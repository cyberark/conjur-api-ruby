#!/usr/bin/env rake
require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new :spec
rescue LoadError
  warn "rspec-core not found, rspec task will be unavailable"
end

begin
  require "yard"
  YARD::Rake::YardocTask.new(:yard)
rescue LoadError
  warn "yard not found, yard task will be unavailable"
end

task :init_coverage do
  require 'fileutils'
  FileUtils.rm_rf 'coverage'
end

begin
  require 'cucumber'
  require 'cucumber/rake/task'
  task :cucumber do
    FileUtils.rm_rf 'features/reports'
    Cucumber::Rake::Task.new do |t|
      t.cucumber_opts = "--tags ~@wip --format pretty --format junit --out features/reports"
    end.runner.run
  end

  begin
    require 'ci/reporter/rake/rspec'
    desc "Run the spec and cucumber suites, compute the test results and coverage statistics, build Yard docs"
    task :jenkins => [:init_coverage, :"ci:setup:rspec", :spec, :cucumber, :yard]
    task default: [ :jenkins ]
  rescue LoadError
    warn "ci_reporter_rspec not found, jenkins task will be unavailable"
  end
rescue LoadError
  warn "cucumber not found, cucumber task will be unavailable"
end

