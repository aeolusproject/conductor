require 'spec_helper'

describe ApplicationHelper do
  include ApplicationHelper

  context "restful_submit_tag() helper" do

    it "contains mapping as hidden fields" do
      html = restful_submit_tag('Delete', 'destroy', 'destroy_url', 'DELETE')
      doc = Nokogiri::HTML(html)
      nodes = (doc/"input[@type='hidden']")

      nodes.each do |node|
        ['__map[destroy][url]', '__map[destroy][method]'].include?(node['name']).should be_true
      end
    end

    it "with no options" do
      html = restful_submit_tag('Delete', 'destroy', 'destroy_url', 'DELETE')
      doc = Nokogiri::HTML(html)
      node = (doc/"input[@type='submit']")

      node.first['name'].should == '__rewrite[destroy]'
    end

    it "with options" do
      html = restful_submit_tag('Delete', 'destroy', 'destroy_url', 'DELETE', :id => 'delete', :name => 'test')
      doc = Nokogiri::HTML(html)
      node = (doc/"input[@type='submit']")

      node.first['name'].should == '__rewrite[destroy]'
      node.first['id'].should == 'delete'
    end

  end

end
