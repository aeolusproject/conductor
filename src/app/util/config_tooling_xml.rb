#
# Copyright (C) 2011 Red Hat, Inc.
# Written by Greg Blomquist <gblomqui@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

class ConfigToolingXML
  class ValidationError < RuntimeError; end

  class FileXML
    def initialize(xmlstr = "")
      @doc = Nokogiri::XML(xmlstr)
      @root = @doc.root.at_xpath('/file') if @doc.root
    end

    def to_s
      @root.to_s
    end

    def validate!
      raise ValidationError, "File XML root element not found" unless @doc.root
      raise ValidationError, "<file> element not found" unless @root
      errors = []
      errors << "file element does not have a URL" unless url
      raise ValidationError, errors.join(", ") unless errors.empty?
    end

    def url
      @root['url'] if @root
    end
  end

=begin Config Tooling XML Format
  <config-tooling>
    <executable url="http://example.com/config.sh"/>
    <files>
      <file url="http://example.com/file.conf"/>
      <file url="http://example.com/file.tar.gz"/>
    </files>
  </config-tooling>
=end

  def initialize(xmlstr = "")
    @doc = Nokogiri::XML(xmlstr)
    @root = @doc.root.at_xpath('/tooling') if @doc.root
    @executable = @root.at_xpath('executable') if @root
  end

  def to_s
    @root.to_s
  end

  def validate!
    raise ValidationError, "Config Tooling XML root element not found" unless @doc.root
    raise ValidationError, "<tooling> element not found" unless @root
    errors = []
    errors << "executable does not have a URL" if @executable and not @executable['url']
    unless files.empty?
      files.each do |file|
        begin
          file.validate!
        rescue ValidationError => e
          errors << e.message
        end
      end
    end
    raise ValidationError, errors.join(", ") unless errors.empty?
  end

  def executable
    @executable['url'] if @executable
  end

  def files
    @files ||=
      @root.xpath('files/file').collect do |file_node|
      FileXML.new(file_node.to_s)
    end
  end
end
