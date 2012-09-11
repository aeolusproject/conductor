class FakeResponse
  attr_reader :code, :message
  def initialize(code, message)
    @code = code
    @message = message
  end
end
