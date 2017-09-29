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

require 'fileutils'
task(:init_coverage) { FileUtils.rm_rf 'coverage' }
task(:cuke_report_cleanup) { FileUtils.rm_rf 'features/reports' }

begin
  require 'cucumber'
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new(:cucumber) do |t|
    t.cucumber_opts = "--tags 'not @wip' --format pretty --format junit --out features/reports"
  end

  begin
    require 'ci/reporter/rake/rspec'
    desc "Run the spec and cucumber suites, compute the test results and coverage statistics, build Yard docs"
    task :jenkins => [:init_coverage, :"ci:setup:rspec", :spec, :cuke_report_cleanup, :cucumber, :yard]
    task default: [ :jenkins ]
  rescue LoadError
    warn "ci_reporter_rspec not found, jenkins task will be unavailable"
  end
rescue LoadError
  warn "cucumber not found, cucumber task will be unavailable"
end

