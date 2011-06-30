module Aeolus
  module Image
    class ListCommand < BaseCommand
      def initialize(opts={}, logger=nil)
        super(opts, logger)
      end

      def images
        doc = Nokogiri::XML iwhd['/images'].get
        doc.xpath("/objects/object/key").collect { |node| "uuid: " + node.text }
      end

      def builds
        not_implemented
      end

      def targetimages
        not_implemented
      end

      def targets
        not_implemented
      end

      def providers
        print_values = [["NAME", "TYPE", "URL"]]

        doc = Nokogiri::XML conductor['/providers'].get
        doc.xpath("/providers/provider").each do |provider|
          print_values << [provider.xpath("name").text, provider.xpath("provider_type").text, provider.xpath("url").text]
        end

        format_print(print_values)
        quit(0)
      end

      def accounts
        not_implemented
      end

      private
      # Takes a 2D array of strings and neatly prints them to STDOUT
      def format_print(print_values)
        widths =  Array.new(print_values[0].size, 0)
        print_values.each do |print_value|
          widths = widths.zip(print_value).map! {|width, value| value.length > width ? value.length : width }
        end

        print_values.each do |print_value|
          widths.zip(print_value) do |width, value|
            printf("%-#{width + 5}s", value)
          end
          puts ""
        end
      end
    end
  end
end
