require 'util/repository_manager/abstract_repository'
require 'open-uri'

class CompsRepository < AbstractRepository
  def initialize(conf)
    super
    @baseurl = conf['baseurl']
    @cache_dir = "#{RAILS_ROOT}/config/image_descriptor_xmls"
    @cache_file = File.join(@cache_dir, "#{@id}.data")
    @repomd_url = File.join(@baseurl, 'repodata', 'repomd.xml')
  end

  def groups
    begin
      @groups ||= Marshal.load(File.open(@cache_file, 'r'))
    rescue Errno::ENOENT
      raise "failed to read cached packages info, run 'rake dc:prepare_repos'"
    end
  end

  def prepare_repo
    grps = {}
    @all_pkgs = pkg_names
    group_nodes.each do |g|
      pkgs = group_packages(g)
      next if pkgs.empty?
      name = g.at_xpath('name').text
      grps[name] = {
        :name => name,
        :repository_id => @id,
        :packages => pkgs
      }
    end

    other = {}
    @all_pkgs.each do |pkg, val|
      other[pkg] = {:type => 'optional'} if val != :listed
    end
    if other.size > 0
      name = 'unsorted'
      grps[name]  = {
        :name => name,
        :repository_id => @id,
        :packages => other
      }
    end

    Dir.mkdir(@cache_dir) unless File.directory?(@cache_dir)
    Marshal.dump(grps, File.open(@cache_file, 'w'))
  end

  private

  def group_nodes
    return [] unless data = group_xml
    xml = Nokogiri::XML(data)
    xml.xpath('/comps/group')
  end

  def pkg_names
    pkgs = {}
    xml = Nokogiri::XML(primary_xml)
    xml.xpath('/xmlns:metadata/xmlns:package').each do |node|
      next unless name = node.at_xpath('./xmlns:name/child::text()')
      pkgs[name.text] = true
    end
    return pkgs
  end

  def download_xml(url)
    resp = Typhoeus::Request.get(url, :timeout => 30000, :follow_location => true, :max_redirects => 3)
    unless resp.code == 200
      raise "failed to fetch #{url}: #{resp.body}"
    end
    if url =~ /\.gz$/
      return Zlib::GzipReader.new(StringIO.new(resp.body)).read
    else
      return resp.body
    end
  end

  def repomd
    @repomd ||= Nokogiri::XML(download_xml(@repomd_url))
  end

  def primary_xml
    unless primary = repomd.xpath("/xmlns:repomd/xmlns:data[@type=\"primary\"]/xmlns:location").first
      raise "there is no 'primary' info in the repomd.xml (#{@repomd_url})"
    end
    download_xml(File.join(@baseurl, primary['href']))
  end

  def group_xml
    # we don't raise exception if group is missing - group is not required
    if group = repomd.xpath("/xmlns:repomd/xmlns:data[@type=\"group\"]/xmlns:location").first
      download_xml(File.join(@baseurl, group['href']))
    else
      nil
    end
  end

  def group_packages(group_node)
    pkgs = {}
    group_node.xpath('packagelist/packagereq').each do |p|
      pkg_name = p.text
      next unless val = @all_pkgs[pkg_name]
      val = :listed
      (pkgs[pkg_name] ||= {})[:type] = p.attr('type')
    end
    return pkgs
  end
end
