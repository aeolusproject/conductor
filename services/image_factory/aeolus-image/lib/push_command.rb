require 'rest_client'

module Aeolus
  module Image
    class PushCommand < BaseCommand
      attr_accessor :console
      def initialize(opts={}, logger=nil)
        super(opts, logger)
        default = {
          :provider => [],
          :id => '',
          :build => ''
        }
        @options = default.merge(@options)
        @console = ImageFactoryConsole.new()
        @console.start
      end
      def run
        if combo_implemented?
          sleep(5)
          @console.push(@options[:provider], get_creds, @options[:id], @options[:build]).each do |adaptor|
            puts ""
            puts "Provider Image: #{adaptor.image_id}"
            puts "Image: #{adaptor.image}"
            puts "Build: #{adaptor.build}"
            puts "Status: #{adaptor.status}"
            puts "Percent Complete: #{adaptor.percent_complete}"
          end
          quit(0)
        end
      end

      def get_creds
        conductor['provider_accounts'].get
      end

      def combo_implemented?
        if @options[:provider].empty? || @options[:id].empty?
          puts "This combination of parameters is not currently supported"
          quit(1)
        end
        true
      end

      private
      def quit(code)
        @console.shutdown
        exit(code)
      end
    end
  end
end
