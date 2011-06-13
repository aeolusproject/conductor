module Aeolus
  module Image
    class ImportCommand < BaseCommand
      def initialize(opts={}, logger=nil)
        super(opts, logger)
        default = {
          :image => '',
          :build => '',
          :id => '',
          :description => '<image><name>' + @options[:id] + '</name></image>',
          :target => '',
          :provider => ''
        }
        @options = default.merge(@options)
        @console = ImageFactoryConsole.new()
        @console.start
      end

      def import_image
        description = read_file(@options[:description])
        if !description.nil?
          @options[:description] = description
        end
        # TODO: Validate Description XML

        #This is a temporary hack in case the agent doesn't show up on bus
        #immediately
        sleep(5)
        import_map = @console.import_image(@options[:image], @options[:build], @options[:id], @options[:description], @options[:target].first, @options[:provider].first)
        puts ""
        puts "Target Image: " + import_map['target_image']
        puts "Image: " + import_map['image']
        puts "Build: " + import_map['build']
        puts "Provider Image: " + import_map['provider_image']
        quit(0)
      end

      def quit(code)
        @console.shutdown
        super
      end
    end
  end
end
