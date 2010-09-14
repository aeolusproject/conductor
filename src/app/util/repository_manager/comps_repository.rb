require 'util/repository_manager/abstract_repository'
require 'open-uri'

class CompsRepository < AbstractRepository
  def initialize(conf)
    super
    @baseurl = conf['baseurl']
  end

  def packages
    packages = []
    get_packages_nodes.each do |node|
      name = node.at_xpath('./xmlns:name/child::text()')
      group = node.at_xpath('./xmlns:format/rpm:group/child::text()')
      description = node.at_xpath('./xmlns:description/child::text()')
      next unless name and group
      packages << {
        :repository_id => @id,
        :name => name.text,
        :description => description ? description.text : '',
      }
    end
    return packages
  end

  def groups
    groups = {}
    get_groups_nodes.each do |g|
      pkgs = get_group_packages(g)
      next if pkgs.empty?
      name = g.at_xpath('name').text
      groups[name] = {
        :name => name,
        :description => (t = g.at_xpath('description')) ? t.text : '',
        :packages => pkgs,
      }
    end
    return groups
  end

  def download_xml(type)
    begin
      url = get_url(type)
    rescue
      return ''
    end

    xml_data = open(url)
    if url =~ /\.gz$/
      return Zlib::GzipReader.new(xml_data).read
    else
      return xml_data.read
    end
  end

  private

  def get_xml(type)
    # FIXME: I'm not sure config is right dir for automatic storing of
    # xml files, but this should be temporary solution until Image Repo is
    # done
    xml_dir = "#{RAILS_ROOT}/config/image_descriptor_xmls"
    xml_file = "#{xml_dir}/#{@id}.#{type}.xml"
    begin
      return File.open(xml_file) { |f| f.read }
    rescue
      xml = download_xml(type)
      Dir.mkdir(xml_dir) unless File.directory?(xml_dir)
      File.open(xml_file, 'w') { |f| f.write xml }
      return xml
    end
  end

  def get_group_packages(group_node)
    pkgs = {}
    group_node.xpath('packagelist/packagereq').each do |p|
      pkgs[p.text] = p.attr('type')
    end
    return pkgs
  end

  def get_packages_nodes
    unless @packages_nodes
      data = get_xml('primary')
      xml = Nokogiri::XML(data)
      @packages_nodes = xml.xpath('/xmlns:metadata/xmlns:package')
    end
    return @packages_nodes
  end

  def get_groups_nodes
    unless @groups_nodes
      data = get_xml('group')
      xml = Nokogiri::XML(data)
      @groups_nodes = xml.xpath('/comps/group')
    end
    return @groups_nodes
  end

  def get_url(type)
    if type == 'repomd'
      return File.join(@baseurl, 'repodata', 'repomd.xml')
    else
      location = repomd.xpath("/xmlns:repomd/xmlns:data[@type=\"#{type}\"]/xmlns:location").first
      raise "location for #{type} data not found" unless location
      return File.join(@baseurl, location['href'])
    end
  end

  def repomd
    unless @repomd
      @repomd = Nokogiri::XML(get_xml('repomd'))
    end
    return @repomd
  end
end
