$: << File.expand_path(File.dirname(__FILE__) + '.')
require 'image_factory_connector'

@l = Logger.new(STDOUT)
@l.level = Logger::DEBUG

@console = ImageFactoryConsole.new({:handler=>FactoryRestHandler.new(@l), :logger =>@l})
@console.start

run ImageFactoryConnector

ImageFactoryConnector.set :console, @console
ImageFactoryConnector.set :logger, @l
