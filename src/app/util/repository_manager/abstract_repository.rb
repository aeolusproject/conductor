class AbstractRepository
  attr_reader :id, :name, :baseurl, :yumurl

  def initialize(conf)
    @id = conf['id']
    @name = conf['name']
    @baseurl = conf['baseurl']
    @yumurl = conf['yumurl'] || conf['baseurl']
  end
end
