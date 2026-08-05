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

  # Cloud-authenticator features (authn-iam / authn-azure / authn-jwt gcp) are
  # live integration tests that only work on the matching cloud agent, so they
  # are excluded from the default suite and opted into via the CLOUD_AUTHN_TAG
  # env var by the dedicated jenkins_cucumber_cloud task.
  CLOUD_AUTHN_TAGS = %w[@authn_iam @authn_azure @authn_gcp].freeze

  Cucumber::Rake::Task.new(:cucumber) do |t|
    exclude = (['@wip'] + CLOUD_AUTHN_TAGS).map { |tag| "not #{tag}" }.join(' and ')
    t.cucumber_opts = "--tags '#{exclude}' --format pretty --format junit --out features/reports"
  end

  # Runs a single cloud-authenticator feature, selected by CLOUD_AUTHN_TAG
  # (e.g. CLOUD_AUTHN_TAG=@authn_iam). Used by the cloud CI stages.
  #
  # NOTE: this block runs at Rakefile load time, so it must not raise when
  # CLOUD_AUTHN_TAG is unset (that would break every other rake invocation).
  # The value is validated in the :validate_cloud_authn_tag prerequisite,
  # which only runs when this task is actually invoked. The fallback tag here
  # is only a placeholder for the load-time cucumber_opts string.
  Cucumber::Rake::Task.new(:cucumber_cloud) do |t|
    tag = ENV['CLOUD_AUTHN_TAG'].to_s.empty? ? '@authn_iam' : ENV['CLOUD_AUTHN_TAG']
    t.cucumber_opts = "--tags '#{tag}' --format pretty --format junit --out features/reports"
  end

  task :validate_cloud_authn_tag do
    if ENV['CLOUD_AUTHN_TAG'].to_s.empty?
      raise 'CLOUD_AUTHN_TAG must be set (e.g. @authn_iam) to run jenkins_cucumber_cloud'
    end
  end

  begin
    require 'ci/reporter/rake/rspec'
    desc "Run the spec and cucumber suites, compute the test results and coverage statistics, build Yard docs"
    task :jenkins_init => [ :init_coverage, :cuke_report_cleanup ]
    task :jenkins_spec => [ :"ci:setup:rspec", :spec ]
    task :jenkins_cucumber => [ :cucumber ]
    task :jenkins_cucumber_cloud => [ :validate_cloud_authn_tag, :cucumber_cloud ]
  rescue LoadError
    warn "ci_reporter_rspec not found, jenkins task will be unavailable"
  end
rescue LoadError
  warn "cucumber not found, cucumber task will be unavailable"
end

