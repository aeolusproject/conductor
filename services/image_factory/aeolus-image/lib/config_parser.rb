require 'optparse'
require 'logger'
require 'base_command'
require 'list_command'
require 'build_command'
require 'push_command'
require 'import_command'
require 'delete_command'

module Aeolus
  module Image
    class ConfigParser
      COMMANDS = %w(list build push import delete)
      attr_accessor :options, :command, :args

      def initialize(argv)
        @args = argv
        # Default options
        @options = {}
        parse
      end

      def process
        # Check for command, then call appropriate Optionparser and initiate
        # call to that class.
        @command = @args.shift
        # Eventually get the config file from user dir if it exists.
        # File.expand_path("~")
        if COMMANDS.include?(@command)
          self.send(@command.to_sym)
        else
          @args << "-h"
          puts "Valid command required: \n\n"
          parse
        end
      end

      private
      def parse
        @optparse ||= OptionParser.new do|opts|
          opts.banner = "Usage: aeolus-image [#{COMMANDS.join('|')}] [general options] [command options]"

          opts.separator ""
          opts.separator "General options:"
          opts.on('-u', '--user USERNAME', 'Conductor username') do |user|
            @options[:user] = user
          end
          opts.on('-w', '--password PASSWORD', 'Conductor password') do |pw|
            @options[:password] = pw
          end
          opts.on('-d', '--id ID', 'id for a given object') do |id|
            @options[:id] = id
          end
          opts.on('-r', '--provider NAME', 'name of specific provider (ie ec2-us-east1)') do |name|
            @options[:provider] = name
          end
          opts.on('-I', '--image ID', 'ID of the base image, can be used in build and push commands, see examples') do |id|
            @options[:image] = id
          end
          opts.on('-d', '--daemon', 'run as a background process') do
            @options[:subcommand] = :images
          end
          opts.on( '-h', '--help', 'Get usage information for this tool') do
            puts opts
            exit(0)
          end

          opts.separator ""
          opts.separator "List options:"
          opts.on('-i', '--images', 'Retrieve a list of images') do
            @options[:subcommand] = :images
          end
          opts.on('-b', '--builds ID', 'Retrieve the builds of an image') do |id|
            @options[:subcommand] = :builds
            @options[:id] = id
          end
          opts.on('-t', '--targetimages ID', 'Retrieve the target images from a build') do |id|
            @options[:subcommand] = :targetimages
            @options[:id] = id
          end
          opts.on('-P', '--providerimages ID', 'Retrieve the provider images from a target image') do |id|
            @options[:subcommand] = :targetimages
            @options[:id] = id
          end
          opts.on('-g', '--targets', 'Retrieve the values available for the --target parameter') do
            @options[:subcommand] = :targets
          end
          opts.on('-p', '--providers', 'Retrieve the values available for the --provider parameter') do
            @options[:subcommand] = :providers
          end
          opts.on('-a', '--accounts', 'Retrieve the values available for the --account parameter') do
            @options[:subcommand] = :accounts
          end

          opts.separator ""
          opts.separator "Build options:"
          opts.on('-T', '--target TARGET1,TARGET2', Array, 'provider type (ec2, rackspace, rhevm, etc)') do |name|
            @options[:target] = name
          end
          opts.on('-e', '--template FILE', 'path to file that contains template xml') do |file|
            @options[:template] = file
          end

          opts.separator ""
          opts.separator "Push options:"
          opts.on('-B', '--build ID', 'push all target images for a build, to same providers as previously') do |id|
            @options[:build] = id
          end
          opts.on('-A', '--account NAME', 'name of specific provider account to use for push') do |name|
            @options[:account] = name
          end

          opts.separator ""
          opts.separator "Delete options:"
          opts.on('-m', '--targetimage ID', 'delete target image and its provider images') do |id|
            @options[:targetimage] = id
          end
          opts.on('-D', '--providerimage ID', 'delete provider image') do |id|
            @options[:providerimage] = id
          end

          opts.separator ""
          opts.separator "List Examples:"
          opts.separator "aeolus-image list --images                  # list available images"
          opts.separator "aeolus-image list --builds $image_id        # list the builds of an image"
          opts.separator "aeolus-image list --targetimages $build_id  # list the target images from a build"
          opts.separator "aeolus-image list --targets                 # list the values available for the --target parameter"
          opts.separator "aeolus-image list --providers               # list the values available for the --provider parameter"
          opts.separator "aeolus-image list --accounts                # list the values available for the --account parameter"

          opts.separator ""
          opts.separator "Build examples:"
          opts.separator "aeolus-image build --target ec2 --template my.tmpl  # build a new image for ec2 from the template"
          opts.separator "aeolus-image build --image $image_id                # rebuild the image template and targets from latest build"
          opts.separator %q{aeolus-image build --target ec2,rackspace \         # rebuild the image with a new template and set of targets
                   --image $image_i \
                   --template my.tmpl}

          opts.separator ""
          opts.separator "Push examples:"
          opts.separator "aeolus-image push --provider ec2-us-east-1 --id $target_image_id  # push the target image to the specified provider"
          opts.separator "aeolus-image push --build $build_id                               # push all target images for a build, to same providers as previously"
          opts.separator "aeolus-image push --account $provider_account --build $build_id   # ditto, using a specific provider account"
          opts.separator "aeolus-image push --image $image_id                               # push all the target images for the latest build"

          opts.separator ""
          opts.separator "Import examples:"
          opts.separator "aeolus-image import --provider ec2-us-east-1 --id $ami_id  # import an AMI from the specified provider"

          opts.separator ""
          opts.separator "Delete examples:"
          opts.separator "aeolus-image delete --build $build_id               # deletes a build, updating latest/parent references as appropriate"
          opts.separator "aeolus-image delete --targetimage $target_image     # deletes a target image and its provider images"
          opts.separator "aeolus-image delete --providerimage $provider_image # deletes a provider image"
        end

        begin
          @optparse.parse!(@args)
        rescue OptionParser::InvalidOption
          puts "Warning: Invalid option"
          exit(0)
        end
      end

      # TODO: Remove all this boilerplate and replace with some metaprogramming,
      # perhaps method_missing
      def list
        # TODO: Instantiate and call object matching command type, for example:
        # l = ListCommand.new(@options)
        # Each Command will call it's own internal method depending on the contents of the hash.
        # For the list example above, that object would call a method 'images' based on the item
        # @options[:subcommand] being :images, so internally that class may do something like:
        # self.send(@options[:subcommand])
        "Not implemented"
      end

      def build
        b = BuildCommand.new(@options)
        b.run
      end

      def push
        "Not implemented"
      end

      def import
        "Not implemented"
      end

      def delete
        "Not implemented"
      end
    end
  end
end
