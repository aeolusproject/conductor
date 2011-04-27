class AbstractRepository
  attr_reader :id, :name, :baseurl, :yumurl, :type, :platform_id, :install

  def initialize(conf)
    @id = conf['id']
    @name = conf['name']
    @baseurl = conf['baseurl']
    @yumurl = conf['yumurl'] || conf['baseurl']
    @type = conf['type']
    @platform_id = conf['platform_id']
    @install = conf['install'] || false
  end

  def search_package(what)
    packages.select {|p| p[:name] =~ /#{Regexp.escape(what)}/i}
  end
end
