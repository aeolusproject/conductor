require 'image_factory'

module Aeolus
  module Image
    class BuildCommand < BaseCommand
      attr_accessor :console
      def initialize(opts={}, logger=nil)
        super(opts, logger)
        default = {
          :template_str => '',
          :template => '',
          :target => [],
          :image => '',
          :build => ''
        }
        @options = default.merge(@options)
        @console = ImageFactoryConsole.new()
        @console.start
      end

      def run
        if combo_implemented?
          read_file
          #This is a temporary hack in case the agent doesn't show up on bus immediately
          sleep(5)
          @console.build(@options[:template_str], @options[:target], @options[:image]).each do |adaptor|
            puts ""
            puts "Target Image: #{adaptor.image_id}"
            puts "Image: #{adaptor.image}"
            puts "Build: #{adaptor.build}"
            puts "Status: #{adaptor.status}"
            puts "Percent Complete: #{adaptor.percent_complete}"
          end
          quit(0)
        end
      end

      #TODO: Consider if this and the next method should be protected or private
      def read_file
        full_path = File.expand_path(@options[:template])
        if File.exist?(full_path) && !File.directory?(full_path)
          @options[:template_str] = File.read(File.expand_path(@options[:template]))
        else
          puts "Cannot find specified file"
          quit(1)
        end
      end

      def combo_implemented?
        if @options[:template].empty? || @options[:target].empty?
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
