Then(/^I(?: can)? run the code:$/) do |code|
  @result = eval(code).tap do |result|
    puts result if ENV['DEBUG']
  end
end

Then(/^this code should fail with "([^"]*)"$/) do |error_msg, code|
  begin
    @result = eval(code)
  rescue Exception => exc
    if not exc.message =~ %r{#{error_msg}}
      fail "'#{error_msg}' was not found in '#{exc.message}'"
    end
  else
    puts @result if ENV['DEBUG']
    fail "The provided block did not raise an error"
  end
end
