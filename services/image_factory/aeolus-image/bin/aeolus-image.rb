#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'config_parser.rb'
parser = Aeolus::Image::ConfigParser.new(ARGV)
puts parser.process
