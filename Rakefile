#!/usr/bin/env rake
require "bundler/gem_tasks"

Dir[File.expand_path('../tasks/**.rake', __FILE__)].each do |f|
  begin
    load f
  rescue LoadError
    # pass through
  end
end
