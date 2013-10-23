desc 'Regenerate copyright headers'
task :headers do
  begin
    require 'copyright_header'
  rescue LoadError
    warn "Please gem install copyright-header"
    exit false
  end

  BASEPATH = File.expand_path('../..', __FILE__)

  spec = Gem::Specification::load Dir.glob(BASEPATH + '/*.gemspec').first

  args = {
    license: spec.license,
    copyright_holders: ['Conjur Inc.'],
    copyright_years: ["2012-#{Time.new.year}"],
    copyright_software: 'Conjur',
    copyright_software_description: spec.description,
    guess_extension: true,
    add_path: 'lib',
    output_dir: BASEPATH + '/'
  }

  command_line = CopyrightHeader::CommandLine.new( args )
  command_line.execute
end
