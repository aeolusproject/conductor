class GraphService
  require 'gnuplot'
  require 'nokogiri'
  require 'scruffy'

  DATA_SERVICE = DataServiceActiveRecord

  def self.dashboard_quota (user,opts = {})
    #FIXME add permission checks to filter what graphs user can get
    graphs = Hash.new

    #if a specific cloud account is given, just return that cloud account's graph.
    #otherwise return all graphs user has permission to see.
    if opts[:cloud_account]
      cloud_account = opts[:cloud_account]
      cloud_account_graphs = Hash.new
      cloud_account_graphs[Graph::QUOTA_INSTANCES_IN_USE] = qos_failure_rate_graph(parent, opts = {})
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

  def self.dashboard_quota_usage(user, opts = {})
    parent = opts[:parent]

    graphs = Hash.new
    graphs[parent] = quota_usage_graph(parent, opts)

    return graphs
  end

  def self.dashboard_qos_avg_time_to_submit_graph(user, opts = {})
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

  def self.dashboard_instances_by_provider (user,opts = {})
    #FIXME add permission checks to see if user can view this graph
    graphs = Hash.new
    graphs[Graph::INSTANCES_BY_PROVIDER_PIE] = instances_by_provider_pie(opts)
    graphs
  end

  private
  def self.gnuplot_open( persist=false )
    cmd = Gnuplot.gnuplot( persist ) or raise 'gnuplot not found'
    output_stream = IO::popen( cmd, "r+")
  end

  def self.quota_usage_graph (parent, opts = {})
    x = [1,2]

    #we'll just have zero values for the unexpected case where cloud_account has no quota
    y = x.collect { |v| 0 }
    if parent.quota
      quota = parent.quota
      data_point = DataServiceActiveRecord.quota_usage(parent, opts[:resource_name])
      #Handle No Limit case
      if data_point.max == Quota::NO_LIMIT
        y = [data_point.used, nil]
      else
        y = [data_point.used, data_point.max]
      end
    end

    chart_opts = {:x => x, :y => y}

    graphs = Hash.new
    graphs[Graph.get_quota_usage_graph_name(opts[:resource_name])] = draw_bar_chart(opts, chart_opts)
    return graphs
  end

  def self.qos_avg_time_to_submit_graph(parent, opts = {})
    start_time = Time.parse(opts[:start_time])
    end_time = Time.parse(opts[:end_time])
    interval_length = opts[:interval_length].to_f
    action = opts[:task_action]

    stats = DATA_SERVICE.qos_task_submission_stats(parent, start_time, end_time, interval_length, action)
    data = get_data_from_stats(stats, "average")
    draw_line_graph(opts, data)
  end

  def self.qos_failure_rate_graph(parent, opts = {})
    start_time = Time.parse(opts[:start_time])
    end_time = Time.parse(opts[:end_time])
    interval_length = opts[:interval_length].to_f
    failure_code = opts[:failure_code]

    stats = DATA_SERVICE.qos_failure_rate_stats(parent, start_time, end_time, interval_length, failure_code)
    data = get_data_from_stats(stats, "failure_rate")
    data[:y_range] = "[0:100]"
    draw_line_graph(opts, data)
  end

  def self.qos_avg_time_to_complete_life_cycle_event(parent, opts = {})
    start_time = Time.parse(opts[:start_time])
    end_time = Time.parse(opts[:end_time])
    interval_length = opts[:interval_length].to_f
    action = opts[:task_action]

    stats = DATA_SERVICE.qos_task_completion_stats(parent, start_time, end_time, interval_length, action)
    data = get_data_from_stats(stats, "average")
    draw_line_graph(opts, data)
  end

  def self.instances_by_provider_pie (opts = {})
    pie_opts = {}
    providers = Provider.all
    providers.each do |provider|
      running_instances = 0
      provider.cloud_accounts.each do |account|
        running_instances = running_instances + account.quota.running_instances if account.quota
      end
      if running_instances > 0
        pie_opts[:"#{provider.name}"] = running_instances
      end
    end

    return draw_pie_chart(opts, pie_opts)
  end

  def self.get_data_from_stats(stats, type)
    x = []
    y = []
    y_max = 0
    for i in 0...stats.length do
      x << i
      y_value = stats[i][type]
      if y_value
        y << y_value
        if y_value > y_max
          y_max = y_value
        end
      else
        y << 0
      end
    end

    if y_max == 0
      y_max = 1
    else
      y_max = y_max * 1.1
    end

    y_range = "[0:" + y_max.to_s + "]"
    return { :x => x, :y => y, :y_range => y_range }
  end

  def self.draw_pie_chart(opts, pie_opts)
    #things we're checking for in opts: :height, :width
    height = 200 unless opts[:height].nil? ? nil : height = opts[:height].to_i
    width =  300 unless  opts[:width].nil? ? nil : width  = opts[:width].to_i

    graph = Graph.new

    mytheme = Scruffy::Themes::Keynote.new
    mytheme.background = :white
    mytheme.marker = :black #sets the label text color
    mytheme.colors = %w(#00689a #00b0e0)

    scruffy_graph = Scruffy::Graph.new({:theme => mytheme})
    scruffy_graph.renderer = Scruffy::Renderers::Pie.new
    scruffy_graph.add :pie, '', pie_opts

    raw_svg = scruffy_graph.render :width => width, :height => height

    xml = Nokogiri::XML(raw_svg)
    svg = xml.css 'svg'
    svg.each do |node|
      node.set_attribute 'viewBox',"0 0 #{width} #{height}"
    end

    xml.root.traverse do |node|
      if node.name == 'text'
        if node.has_attribute? 'font-family'
          node.set_attribute 'font-family','sans-serif'
        end
        if (node.has_attribute? 'font-size') && node.get_attribute('font-size').length > 0
          size = node.get_attribute('font-size').to_f
          size = size * 1.5
          node.set_attribute 'font-size',size.to_s
        end
      end
    end

    graph.svg = xml.to_s
    graph
  end

  def self.draw_line_graph(opts, data)
    #things we're checking for in opts: :height, :width

    height = 60 unless opts[:height].nil? ? nil : height = opts[:height].to_i
    width = 100 unless  opts[:width].nil? ? nil : width  = opts[:width].to_i

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
      #x = (0..500).collect { |v| v.to_f }

      #walk = 0
      #y = x.collect { |v| rand > 0.5 ? walk = walk + 1 : walk = walk - 1 }

      x = data[:x]
      y = data[:y]
      y_range = data[:y_range]

      #plot.set "yrange [-50:50]"
      plot.set "yrange " + y_range

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

  def self.draw_bar_chart(opts, chart_opts)

    #things we're checking for in opts: :max_value, :height, :width

    unless max_value = opts[:max_value]
      max_value = 100 unless max_value = Quota.maximum('maximum_running_instances')
    end
    height = 80 unless opts[:height].nil? ? nil : height = opts[:height].to_i
    width = 150 unless  opts[:width].nil? ? nil : width  = opts[:width].to_i

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

      x = chart_opts[:x]
      y = chart_opts[:y]

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

end