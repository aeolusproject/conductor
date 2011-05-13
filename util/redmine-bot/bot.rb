#!/usr/bin/env ruby

require 'rubygems'
require 'cinch'
require 'nokogiri'
require 'pp'
require 'rest-client'
require 'yaml'

class RedmineWatch
  include Cinch::Plugin

  attr_accessor :last_id

  def initialize(*args)
    super
    #TODO: pull this out into a wrapper script.
    bot_conf("#{File.dirname(__FILE__)}/config.yml")
  end

  timer 20, :method => :refresh

  def refresh
    entries = (feed/"feed entry")
    activity = entries.first
    if (activity/'id').text.strip != @last_id
      data = {
        :text => (activity/'title').text.strip,
        :author => (activity/'author name').text.strip,
        :content=> (activity/'content').text,
      }
      project = data[:text].split('-').first.strip
      data[:text].gsub!(/^(.+) \-/, '').strip
      msg = "[#{data[:author]}] [#{project}] #{data[:text]}"
      #msg += "\nComment: #{strip_html(data[:content])}" unless data[:content].empty?
      bot.config.channels.each { |channel| Channel(channel).send msg }
      @last_id = (activity/'id').text.strip
    end
  end

  def strip_html(str)
    str.gsub(/<\/?[^>]*>/, "").gsub(/[\n]+/, "")
  end

  def feed
    client = RestClient::Resource.new(bot_conf[:feed_url]) #, config[:username], config[:password])
    Nokogiri::HTML(client.get)
  end

  def bot_conf(conf=nil)
    unless @bot_conf
      @bot_conf = YAML::load(File.open(conf))
    end
    return @bot_conf
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.net"
    c.channels = ["#aeolus"]
    c.nick = "aeolus|redmine"
    c.verbose = false
    c.plugins.plugins = [RedmineWatch]
  end

  on :channel, /^!halibut (.+)/ do |m, text|
    begin
      m.reply "#{text.strip}: \u000305<`)))><\u000f tail slapped your chest and face"
    rescue Exception => e
      pp e.backtrace
    end
  end
end

bot.start
