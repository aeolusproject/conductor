require 'yaml'
require 'rest_client'
require 'nokogiri'

module Aeolus
  module Image
    #This will house some methods that multiple Command classes need to use.
    class BaseCommand
      attr_accessor :options

      def initialize(opts={}, logger=nil)
        logger(logger)
        @options = opts
        @config_location = "~/.aeolus-cli"
        @config = load_config
      end

      protected
      def not_implemented
        "This option or combination is not yet implemented"
      end

      def logger(logger=nil)
        @logger ||= logger
        unless @logger
          @logger = Logger.new(STDOUT)
          @logger.level = Logger::INFO
          @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
        end
        return @logger
      end

      def iwhd
        create_resource(:iwhd)
      end

      def conductor
        create_resource(:conductor)
      end

      def read_file(path)
        begin
          full_path = File.expand_path(path)
          if is_file?(path)
            File.read(full_path)
          else
            return nil
          end
        rescue
          nil
        end
      end

      # TODO: Consider ripping all this file-related stuff into a module or
      # class for better encapsulation and testability
      def is_file?(path)
        full_path = File.expand_path(path)
        if File.exist?(full_path) && !File.directory?(full_path)
          return true
        end
        false
      end

      def quit(code)
        exit(code)
      end

      def validate_xml_document(schema_path, xml_string)
        schema = Nokogiri::XML::RelaxNG(File.read(schema_path))
        doc = Nokogiri::XML xml_string
        schema.validate(doc)
      end

      private
      def load_config
        begin
          file_str = read_file(@config_location)
          if is_file?(@config_location) && !file_str.include?(":url")
            lines = File.readlines(File.expand_path(@config_location)).map do |line|
              "#" + line
            end
            File.open(File.expand_path(@config_location), 'w') do |file|
              file.puts lines
            end
            write_file
          end
          write_file unless is_file?(@config_location)
          YAML::load(File.open(File.expand_path(@config_location)))
        rescue Errno::ENOENT
          #TODO: Create a custom exception to wrap CLI Exceptions
          raise "Unable to locate or write configuration file: \"" + @config_location + "\""
        end
      end

      def write_file
        example = File.read(File.expand_path(File.dirname(__FILE__) + "/../examples/aeolus-cli"))
        File.open(File.expand_path(@config_location), 'a+') do |f|
          f.write(example)
        end
      end

      def create_resource(resource_name)
        # Check to see if config has a resource with this name
        if !@config.has_key?(resource_name)
          raise "Unable to determine resource: " + resource_name.to_s + " from configuration file.  Please check: " + @config_location
          return
        end

        #Use command line arguments for username/password
        if @options.has_key?(:username)
          if @options.has_key?(:password)
            RestClient::Resource.new(@config[resource_name][:url], :user => @options[:username], :password => @options[:password])
          else
            #TODO: Create a custom exception to wrap CLI Exceptions
            raise "Password not found for user: " + @options[:username]
          end

        #Use config for username/password
        elsif @config[resource_name].has_key?(:username)
          if @config[resource_name].has_key?(:password)
            RestClient::Resource.new(@config[resource_name][:url], :user => @config[resource_name][:username], :password => @config[resource_name][:password])
          else
            #TODO: Create a custom exception to wrap CLI Exceptions
            raise "Password not found for user: " + @config[resource_name][:username]
          end

        # Do not use authentication
        else
          RestClient::Resource.new(@config[resource_name][:url])
        end
      end
    end
  end
end
