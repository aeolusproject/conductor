#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'rubygems'

require 'rest-client'
require 'nokogiri'

#TODO: perform iwhd version-dependent URI mapping

module Warehouse

  class BucketObject
    attr_reader :key

    def initialize(connection, key, bucket)
      @connection = connection
      @key = key
      @bucket = bucket
      @path = "/#{@bucket.name}/#{@key}"
    end

    def self.create(connection, key, bucket, body, attrs = {})
      obj = new(connection, key, bucket)
      obj.set_body(body)
      obj.set_attrs(attrs)
      obj
    end

    def body
      @connection.do_request @path, :plain => true
    end

    def set_body(body)
      @connection.do_request @path, :content => body, :method => :put
    end

    def attr_list
      result = @connection.do_request @path, :content => 'op=parts', :method => :post
      return result.xpath('/object/object_attr/@name').to_a.map {|item| item.value}
    end

    def attrs(list)
      attrs = {}
      list.each do |att|
        next if att.match('-')
        attrs[att] = (@connection.do_request("#{@path}/#{att}", :plain => true) rescue nil)
      end
      attrs
    end

    def attr(name)
      attrs([name]).first
    end

    def set_attrs(hash)
      hash.each do |name, content|
        set_attr(name, content)
      end
    end

    def set_attr(name, content)
      path = "#{@path}/#{name}"
      @connection.do_request path, :content => content, :method => :put
    end

    def delete!
      @connection.do_request @path, :method => :delete
      true
    end

  end

  class Bucket
    attr_accessor :name

    def initialize(name, connection)
      @name = name
      @connection = connection
    end

    def to_s
      "Bucket: #{@name}"
    end

    def object_names
      result = @connection.do_request "/#{@name}"
      result.xpath('/objects/object').map do |obj|
        obj.at_xpath('./key/text()').to_s
      end
    end

    def objects
      object_names.map do |name|
        object(name)
      end
    end

    def object(key)
      BucketObject.new @connection, key, self
    end

    def create_object(key, body, attrs)
      BucketObject.create(@connection, key, self, body, attrs)
    end

    def include?(key)
      object_names.include?(key)
    end
  end

  class Connection
    attr_accessor :uri

    def initialize(uri)
      @uri = uri
    end

    def do_request(path = '', opts={})
      opts[:method]  ||= :get
      opts[:content] ||= ''
      opts[:plain]   ||= false
      opts[:headers] ||= {}

      result = RestClient::Request.execute :method => opts[:method], :url => @uri + path, :payload => opts[:content], :headers => opts[:headers]

      return Nokogiri::XML result unless opts[:plain]
      return result
    end

  end

  class Client

    def initialize(uri)
      @connection = Connection.new(uri)
    end

    def create_bucket(bucket)
      @connection.do_request "/#{bucket}", :method => :put rescue RestClient::InternalServerError
      Bucket.new(bucket, @connection)
    end

    def bucket(bucket)
      Bucket.new bucket, @connection
    end

    def buckets
      @connection.do_request.xpath('/api/link[@rel="bucket"]').map do |obj|
        obj.at_xpath('./@href').to_s.gsub(/.*\//, '')
      end
    end

    def get_iwhd_version
      result = @connection.do_request.at_xpath('/api[@service="image_warehouse"]/@version')
      raise "Response does not contain <api> tag or version information" if result == nil
      return result.value
    end

    def query(bucket_name, query_string)
      @connection.do_request "/#{bucket_name}/_query", {:method => :post, :content => query_string}
    end
  end

end
