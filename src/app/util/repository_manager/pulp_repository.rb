require 'json'
require 'typhoeus'
require 'util/repository_manager/abstract_repository'

class PulpRepository < AbstractRepository
  class WrappedRestClient
    def self.method_missing(method, *args)
      resp = Typhoeus::Request.send(method, *args)
      unless resp.code == 200
        raise "pulp repository: failed to fetch #{args.first} (code #{resp.code}): #{resp.body}"
      end
      begin
        JSON.parse(resp.body)
      rescue JSON::ParserError
        raise "pulp repository: failed to parse response (#{args.first})"
      end
    end
  end

  HTTP_OPTS = { :disable_ssl_peer_verification => true, :timeout => 30000 }

  def self.repositories(conf)
    WrappedRestClient.get(File.join(conf['baseurl'], "/repositories/"), HTTP_OPTS).map do |r|
      next if conf['except'] and conf['except'].include?(r['id'])
      PulpRepository.new(r.merge('baseurl' => conf['baseurl'],
                                 'yumurl' => File.join(conf['yumurl'], r['id'])))
    end.compact
  end

  def initialize(conf)
    super
    @groups_url = File.join(strip_path(@baseurl), conf['packagegroups'])
    @categories_url = File.join(strip_path(@baseurl), conf['packagegroupcategories'])
    @packages_url = File.join(strip_path(@baseurl), conf['packages'])
  end

  def groups
    groups = {}
    WrappedRestClient.get(@groups_url, HTTP_OPTS).each do |id, info|
      pkgs = {}
      info['default_package_names'].each {|p| pkgs[p] = {:type => 'default'}}
      info['optional_package_names'].each {|p| pkgs[p] = {:type => 'optional'}}
      info['mandatory_package_names'].each {|p| pkgs[p] = {:type => 'mandatory'}}
      next if pkgs.empty?
      name = info['name']
      groups[info['id']] = {
        :name => info['name'],
        :description => info['description'].to_s,
        :repository_id => @id,
        :packages => pkgs,
      }
    end
    return groups
  end

  def categories
    categories = {}
    WrappedRestClient.get(@categories_url, HTTP_OPTS).each do |id, info|
      categories[info['id']] = {
        :name => info['name'],
        :groups => info['packagegroupids'],
      }
    end
    return categories
  end

  def packages
    packages = []
    WrappedRestClient.get(@packages_url, HTTP_OPTS).each do |info|
      packages << info['name']
    end
    return packages
  end

  private

  def strip_path(url)
    uri = URI.parse(url)
    uri.path = ''
    uri.to_s
  end
end
