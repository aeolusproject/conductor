module Aeolus
  module Image
    class ListCommand < BaseCommand
      def initialize(opts={}, logger=nil)
        super(opts, logger)
      end

      def images
        images = [["UUID", "NAME", "TARGET", "OS", "OS VERSION", "ARCH", "DESCRIPTION"]]
        doc = Nokogiri::XML iwhd['/target_images'].get
        # Check for any invalid data in iwhd
        invalid_images = []
        doc.xpath("/objects/object/key").each do |targetimage|
          begin
            build = iwhd["/target_images/" + targetimage.text + "/build"].get
            image = iwhd["/builds/" + build + "/image"].get
            template_info = get_template_info(image, targetimage.text)
            if template_info
              images << template_info
            else
              images << [image, get_image_name(image), iwhd["/target_images/" + targetimage + "/target"].get, "", "", "", ""]
            end
          rescue
            invalid_images << targetimage.text
          end
        end
        format_print(images)

        unless invalid_images.empty?
          puts "\nN.B. following images were not listed, aeolus-image encountered some invalid data in iwhd:"
          puts invalid_images.join "\n"
        end
        quit(0)
      end

      def builds
        doc = Nokogiri::XML iwhd['/builds'].get
        doc.xpath("/objects/object/key").each do |build|
          if iwhd['/builds/' + build.text + "/image"].get == @options[:id]
            puts build.text
          end
        end
        quit(0)
      end

      def targetimages
        doc = Nokogiri::XML iwhd['/target_images'].get
        doc.xpath("/objects/object/key").each do |target_image|
          begin
            if iwhd['/target_images/' + target_image.text + "/build"].get == @options[:id]
              puts target_image.text
            end
          rescue RestClient::ResourceNotFound
          end
        end
        quit(0)
      end

      def targets
        targets = [["NAME", "TARGET CODE"]]
        targets << ["Mock", "mock"]
        targets << ["Amazon EC2", "ec2"]
        targets << ["RHEV-M", "rhevm"]
        targets << ["VMware vSphere", "vsphere"]
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

      def get_template_info(image, targetimage)
        begin
          template = Nokogiri::XML iwhd["/templates/" + iwhd["/target_images/" + targetimage + "/template"].get].get
          [image, template.xpath("/template/name").text,
                  iwhd["/target_images/" + targetimage + "/target"].get,
                  template.xpath("/template/os/name").text,
                  template.xpath("/template/os/version").text,
                  template.xpath("/template/os/arch").text,
                  template.xpath("/template/description").text]
        rescue
        end
      end

      def get_image_name(image)
        begin
          template_xml = Nokogiri::XML iwhd["images/" + image].get
          template_xml.xpath("/image/name").text
        rescue
          ""
        end
      end
    end
  end
end
