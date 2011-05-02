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
    @groups ||= load_data[:groups]
  end

  def categories
    @categories ||= load_data[:categories]
  end

  def packages
    @packages ||= load_data[:packages]
  end

  def prepare_repo
    @all_packages = get_packages
    Dir.mkdir(@cache_dir) unless File.directory?(@cache_dir)
    File.open(@cache_file, 'w') do |f|
      Marshal.dump({
        :packages => @all_packages,
        :groups => get_groups,
        :categories => get_categories
      }, f)
    end
  end

  private

  def get_packages
    packages = package_nodes.map do |node|
      {
        #:id => node.at_xpath('./xmlns:id/child::text()').text,
        :name => node.at_xpath('./xmlns:name/child::text()').text,
        :repository_id => @id,
      }
    end
  end

  def get_groups
    @all_packages_hash = {}
    @all_packages.each {|p| @all_packages_hash[p[:name]] = true}

    group_nodes.map do |g|
      pkgs = group_packages(g)
      next if pkgs.empty?
      {
        :id => g.at_xpath('id').text,
        :name => g.at_xpath('name').text,
        :repository_id => @id,
        :packages => pkgs
      }
    end.compact
  end

  def get_categories
    category_nodes.map do |cat|
      {
        :id => cat.at_xpath('id').text,
        :name => cat.at_xpath('name').text,
        :groups => cat.xpath('./grouplist/groupid').map {|g| g.text}
      }
    end
  end

  def load_data
    unless @load_data
      begin
        File.open(@cache_file, 'r') { |f| @load_data = Marshal.load(f) }
      rescue Errno::ENOENT
        raise "failed to read cached packages info, run 'rake dc:prepare_repos'"
      end
    end
    @load_data
  end

  def parsed_group_xml
    unless @xml
      return nil unless data = group_xml
      @xml = Nokogiri::XML(data)
    end
    @xml
  end

  def group_nodes
    return [] unless xml = parsed_group_xml
    xml.xpath('/comps/group')
  end

  def category_nodes
    return [] unless xml = parsed_group_xml
    xml.xpath('/comps/category')
  end

  def package_nodes
    xml = Nokogiri::XML(primary_xml)
    xml.xpath('/xmlns:metadata/xmlns:package')
  end

  def download_xml(url)
    body = nil
    5.times do |i|
      resp = Typhoeus::Request.get(url, :timeout => 60000, :follow_location => true, :max_redirects => 10)
      if resp.code == 200
        body = resp.body
        break
      end
      sleep 2
    end
    raise "failed to fetch #{url}, aborting" unless body

    if url =~ /\.gz$/
      return Zlib::GzipReader.new(StringIO.new(body)).read
    else
      return body
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
      # skip pkg if it's not in all packages list
      next unless @all_packages_hash[pkg_name]
      (pkgs[pkg_name] ||= {})[:type] = p.attr('type')
    end
    return pkgs
  end
end
