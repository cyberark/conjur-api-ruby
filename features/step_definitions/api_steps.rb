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

Given(/^I retrieve the provider details for OIDC authenticator "([^"]+)"$/) do |service_id|
  provider = $conjur.authentication_providers("authn-oidc").select {|provider_details| provider_details["service_id"] == service_id}
  @login_url = provider[0]["redirect_uri"]
  @nonce = provider[0]["nonce"]
  @code_verifier = provider[0]["code_verifier"]
  puts @login_url
end

Given(/^I retrieve auth info for the OIDC provider with username: "([^"]+)" and password: "([^"]+)"$/) do |username, password|
  res = Net::HTTP.get_response(URI(@login_url))
  raise res if res.is_a?(Net::HTTPError) || res.is_a?(Net::HTTPClientError)

  all_cookies = res.get_fields('set-cookie')
  puts all_cookies
  cookies_arrays = Array.new
  all_cookies.each do |cookie|
    cookies_arrays.push(cookie.split('; ')[0])
  end

  html = Nokogiri::HTML(res.body)
  post_uri = URI(html.xpath('//form').first.attributes['action'].value)

  http = Net::HTTP.new(post_uri.host, post_uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(post_uri.request_uri)
  request['Cookie'] = cookies_arrays.join('; ')
  request.set_form_data({'username' => username, 'password' => password})

  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection)
    response_details = URI.decode_www_form(URI(response['location']).query)
    @auth_body = {code: response_details.assoc('code')[1], nonce: @nonce, code_verifier: @code_verifier}
  end
end
