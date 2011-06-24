$: << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))
$: << File.expand_path(File.join(File.dirname(__FILE__), "."))
require 'rubygems'
require 'config_parser'
require 'stringio'
require 'base_command'
require 'list_command'
require 'build_command'
require 'push_command'
require 'import_command'
require 'delete_command'


module Helpers
  # Silences any stream for the duration of the block.
  #
  #   silence_stream(STDOUT) do
  #     puts 'This will never be seen'
  #   end
  #
  #   puts 'But this will'
  #
  # (Taken from ActiveSupport)
  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null')
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
  end
end

Spec::Runner.configure do |config|
  config.include Helpers
  config.before(:all) do
    Aeolus::Image::BaseCommand.class_eval do
      def load_config
        YAML::load(File.open(File.join(File.dirname(__FILE__), "/../examples/aeolus-cli")))
      end
    end
  end
  config.before(:each) do
    @output = double('output')
    @stdout_orig = $stdout
    $stdout = StringIO.new
    @options = {}
  end
  config.after(:each) do
    $stdout = @stdout_orig
  end
end