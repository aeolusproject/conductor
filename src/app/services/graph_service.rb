class GraphService
  require 'gnuplot'
  require 'nokogiri'

  def self.dashboard_quota (user,opts = {})
    #FIXME add permission checks to filter what graphs user can get
    graphs = Hash.new

    #if a specific cloud account is given, just return that cloud account's graph.
    #otherwise return all graphs user has permission to see.
    if opts[:cloud_account]
      cloud_account = opts[:cloud_account]
      cloud_account_graphs = Hash.new
      cloud_account_graphs[Graph::QUOTA_INSTANCES_IN_USE] = quota_instances_in_use_graph(cloud_account,opts)
      graphs[cloud_account] = cloud_account_graphs
    else
      CloudAccount.all.each do |cloud_account|
        cloud_account_graphs = Hash.new
        cloud_account_graphs[Graph::QUOTA_INSTANCES_IN_USE] = quota_instances_in_use_graph(cloud_account,opts)
        graphs[cloud_account] = cloud_account_graphs
      end
    end
    graphs
  end

  def self.dashboard_qos (user,opts = {})
    #FIXME add permission checks to filter what graphs user can get
    graphs = Hash.new

    #if a specific provider is given, just return that provider's graph.
    #otherwise return all graphs user has permission to see.
    if opts[:provider]
      provider = opts[:provider]
      provider_graphs = Hash.new
      provider_graphs[Graph::QOS_AVG_TIME_TO_SUBMIT] = qos_avg_time_to_submit_graph(provider,opts)
      graphs[provider] = provider_graphs
    else
      Provider.all.each do |provider|
        provider_graphs = Hash.new
        provider_graphs[Graph::QOS_AVG_TIME_TO_SUBMIT] = qos_avg_time_to_submit_graph(provider,opts)
        graphs[provider] = provider_graphs
      end
    end
    graphs
  end

  private
  def self.gnuplot_open( persist=false )
    cmd = Gnuplot.gnuplot( persist ) or raise 'gnuplot not found'
    output_stream = IO::popen( cmd, "r+")
  end

  def self.quota_instances_in_use_graph (cloud_account, opts = {})
    #things we're checking for in opts: :max_value, :height, :width

    unless max_value = opts[:max_value]
      max_value = 100 unless max_value = Quota.maximum('maximum_running_instances')
    end
    height = 80 unless height = opts[:height].to_i
    width = 150 unless width  = opts[:width].to_i


    raw_svg = ""
    gp = gnuplot_open
    Gnuplot::Plot.new( gp ) do |plot|
      plot.terminal "svg size #{width},#{height}"
      plot.arbitrary_lines << "unset xtics"
      plot.arbitrary_lines << "unset x2tics"
      plot.arbitrary_lines << "unset ytics"
      plot.arbitrary_lines << "unset y2tics"
      plot.arbitrary_lines << "unset border"

      plot.set "bmargin","0"
      plot.set "lmargin","0"
      plot.set "rmargin","0"
      plot.set "tmargin","0"
      plot.set "boxwidth 0.9"
      plot.set "style fill solid 1.0"
      plot.set "xrange [.25:2.75]"
      plot.set "yrange [0:#{max_value * 1.5}]" #we want to scale maxvalue 50% larger to leave room for label

      x = [1,2]
      #we'll just have zero values for the unexpected case where cloud_account has no quota
      y = x.collect { |v| 0 }
      if cloud_account.quota
        quota = cloud_account.quota
        y = [quota.running_instances,quota.maximum_running_instances]
      end


      #The two arrays above are three columns of data for gnuplot.
      plot.data << Gnuplot::DataSet.new( [[x[0]], [y[0]]] ) do |ds|
        ds.using = "1:2"
        ds.with = 'boxes linecolor rgb "#8cc63f"'
        ds.notitle
      end

      #The two arrays above are three columns of data for gnuplot.
      plot.data << Gnuplot::DataSet.new( [[x[1]], [y[1]]] ) do |ds|
        ds.using = "1:2"
        ds.with = 'boxes linecolor rgb "#cccccc"'
        ds.notitle
      end


      plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
        ds.using = "1:2:2"
        ds.with = "labels left offset 0,.15 rotate"
        ds.notitle
      end
    end
    gp.flush
    gp.close_write
    gp.read(nil,raw_svg)
    gp.close_read

    #massage the svg so that the histogram's bars are oriented horizontally
    xml = Nokogiri::XML(raw_svg)

    nodes = xml.root.children
    wrapper = Nokogiri::XML::Node.new "g", xml.root

    nodes.each do |node|
      node.parent = wrapper if node.name != "desc" && node.name != "defs"
    end

    wrapper.parent = xml.root
    wrapper.set_attribute 'transform',"translate(#{width},0) rotate(90) scale(#{height * 1.0 / width},#{width * 1.0/ height})"

    text_nodes = []
    xml.root.traverse do |node|
      if node.name == 'text' && node.inner_text.strip =~ /^\d+$/
        if node.parent.name == 'g'
          pparent = node.parent
          text_nodes << pparent
        end
      end
    end

    text_nodes.each do |node|
      attr = node.get_attribute 'transform'
      node.remove_attribute 'transform'
      node.set_attribute 'transform',"#{attr} scale (#{height * 1.0 / width},#{width * 1.0/ height})"
    end

    modified_svg = xml.to_s
    graph = Graph.new
    graph.svg = modified_svg
    graph

  end

  def self.qos_avg_time_to_submit_graph (provider, opts = {})
    #things we're checking for in opts: :height, :width

    height = 60 unless height = opts[:height].to_i
    width = 100 unless width  = opts[:width].to_i

    graph = Graph.new
    gp = gnuplot_open

    Gnuplot::Plot.new( gp ) do |plot|
      plot.terminal "svg size #{width},#{height}"
      plot.arbitrary_lines << "unset xtics"
      plot.arbitrary_lines << "unset x2tics"
      plot.arbitrary_lines << "unset ytics"
      plot.arbitrary_lines << "unset y2tics"
      plot.set "bmargin","0"
      plot.set "lmargin","1"
      plot.set "rmargin","0"
      plot.set "tmargin","0"

      #FIXME: get data from DataService for the provider.
      #For demo, plot a random walk for demo of graph display until we hook into DataService
      #First build two equal-length arrays
      x = (0..500).collect { |v| v.to_f }

      walk = 0
      y = x.collect { |v| rand > 0.5 ? walk = walk + 1 : walk = walk - 1 }
      plot.set "yrange [-50:50]"

      #This type of plot takes two equal length arrays of numbers as input.
      plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
        ds.using = "1:2"
        ds.with = "lines"
        ds.notitle
      end
    end
    gp.flush
    gp.close_write
    gp.read(nil,graph.svg)
    gp.close_read
    graph
  end

end
