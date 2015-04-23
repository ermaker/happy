require 'websocket-eventmachine-client'
require 'fiber'

module Happy
  module Util
    class XRPWebSocket
      def initialize
        @fiber = Fiber.new do
          EM.run do
            ws = WebSocket::EventMachine::Client.connect(uri: 'wss://s1.ripple.com')

            ws.onopen do
              Fiber.yield(ws)
            end

            ws.onmessage do |msg, _|
              Fiber.yield(msg)
            end

            ws.onclose do |*|
              EM.stop
            end
          end
        end
        @ws = @fiber.resume

        if block_given?
          begin
            yield(self)
          ensure
            close
          end
        end
      end

      def request(object)
        JSON.parse(send(object.to_json))
      end

      def send(*args)
        @ws.send(*args)
        @fiber.resume
      end

      def close(*args)
        @ws.close(*args)
        @fiber.resume
      end
    end
  end
end
