# Pull in our VCR configuration
if ENV['VCR_RECORD']
  require File.expand_path(File.dirname(__FILE__) + '../../../spec/vcr_setup.rb')
else
  require File.expand_path(File.dirname(__FILE__) + '../../../spec/vcr_setup_norec.rb')
end
