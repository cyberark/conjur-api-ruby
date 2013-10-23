task :jenkins do
  if ENV['BUILD_NUMBER']
    File.write('build_number', ENV['BUILD_NUMBER'])
  end
  require 'ci/reporter/rake/rspec'
  Rake::Task["ci:setup:rspec"].invoke
  Rake::Task["spec"].invoke
end
