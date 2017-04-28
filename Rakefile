#!/usr/bin/env rake
require "bundler/gem_tasks"
require "yard"
require 'ci/reporter/rake/rspec'
require 'cucumber'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec
YARD::Rake::YardocTask.new(:yard)

task :init_coverage do
  require 'fileutils'
  FileUtils.rm_rf 'coverage'
end

task :cucumber do
  FileUtils.rm_rf 'features/reports'
  Cucumber::Rake::Task.new do |t|
    t.cucumber_opts = "--tags ~@wip --format pretty --format junit --out features/reports"
  end.runner.run
end

desc "Run the spec and cucumber suites, compute the test results and coverage statistics, build Yard docs"
task :jenkins => [:init_coverage, :"ci:setup:rspec", :spec, :cucumber, :yard]

task default: [ :jenkins ]
