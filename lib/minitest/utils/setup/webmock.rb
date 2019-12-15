# frozen_string_literal: true

require "webmock/minitest"

WebMock.disable_net_connect!

def WebMock.requests
  @requests ||= []
end

WebMock.after_request do |request, _response|
  WebMock.requests << request
end

module Minitest
  class Test
    setup do
      WebMock.requests.clear
    end
  end
end
