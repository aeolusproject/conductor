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
        targets = [["NAME", "TARGET CODE"]]
        targets << ["Mock", "mock"]
        targets << ["Amazon EC2", "ec2"]
        targets << ["VMWare VSphere", "vmware"]
        targets << ["Condor Cloud", "condor_cloud"]
        format_print(targets)
        quit(0)
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
        print_values = [["NAME", "PROVIDER", "PROVIDER TYPE"]]
        doc = Nokogiri::XML conductor['/provider_accounts/'].get
        doc.xpath("/provider_accounts/provider_account").each do |account|
          print_values << [account.xpath("name").text, account.xpath("provider").text, account.xpath("provider_type").text]
        end

        format_print(print_values)
        quit(0)
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
