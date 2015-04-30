require 'webmock/minitest'

WebMock.disable_net_connect!(allow: %w[codeclimate.com])

def WebMock.requests
  @requests ||= []
end

WebMock.after_request do |request, response|
  WebMock.requests << request
end

class ActiveSupport::TestCase
  setup do
    WebMock.requests.clear
  end
end
