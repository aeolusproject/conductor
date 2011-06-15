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
    end
  end
end
