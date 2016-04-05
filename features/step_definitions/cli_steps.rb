puts "cli_steps, creating Transform"

Transform /\$ns/ do |s|
  s.gsub('$ns', namespace)
end


