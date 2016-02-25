#!/usr/bin/env rake
require "bundler/gem_tasks"
require "yard"
require 'ci/reporter/rake/rspec'
require 'cucumber'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec
Cucumber::Rake::Task.new :features
YARD::Rake::YardocTask.new(:yard)

task :jenkins => ['ci:setup:rspec', :spec] do
  if ENV['BUILD_NUMBER']
    File.write('build_number', ENV['BUILD_NUMBER'])
  end
  require 'fileutils'
  FileUtils.rm_rf 'features/reports'
  Cucumber::Rake::Task.new do |t|
    t.cucumber_opts = "--tags ~@real-api --format pretty --format junit --out features/reports"
  end.runner.run
  Rake::Task["yard"].invoke
end

task default: [:spec, :features]
