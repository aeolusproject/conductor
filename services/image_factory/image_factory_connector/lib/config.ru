$: << File.expand_path(File.dirname(__FILE__) + '.')
require 'image_factory_connector'
require 'yaml'
puts "connector config points to: #{ENV["CONNECTOR_CONFIG"]}"

@l = Logger.new(STDOUT)
@l.level = Logger::DEBUG

@console = ImageFactoryConsole.new({:handler=>FactoryRestHandler.new(@l, ENV["CONNECTOR_CONFIG"]), :logger =>@l})
@console.start

run ImageFactoryConnector

ImageFactoryConnector.set :console, @console
ImageFactoryConnector.set :logger, @l
