require 'phantomjs/poltergeist'

module Happy
  module Util
    class Router
      Capybara.register_driver(:poltergeist_router) do |app|
        Capybara::Poltergeist::Driver.new(
          app,
          phantomjs: Phantomjs.path,
          js_errors: false
        )
      end

      def initialize
        @session = Capybara::Session.new(:poltergeist_router)
      end

      def reboot
        @session.visit 'http://192.168.0.1'
        @session.fill_in 'username', with: ENV['ROUTER_USERNAME']
        @session.fill_in 'passwd', with: ENV['ROUTER_PASSWORD']
        @session.find(:css, '#submit_bt').click
        @session.visit 'http://192.168.0.1/sess-bin/timepro.cgi?tmenu=background&smenu=reboot&commit=reboot'
      end
    end
  end
end
