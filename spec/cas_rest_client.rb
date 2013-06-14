class MockCasRestClient
  def initialize response
    @response = response
  end

  def new options
    @options = options
    self
  end

  def get url
    @url = url
    @response
  end

  attr_reader :options, :url
end
