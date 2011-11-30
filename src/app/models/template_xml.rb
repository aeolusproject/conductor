#
# Copyright (C) 2011 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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


class TemplateXML
  attr_reader :errors, :doc

  def initialize(xmlstr)
    @errors = []
    @xml = Nokogiri::XML(xmlstr) { |config| config.strict }
    @relax_file = "#{::Rails.root.to_s}/app/util/template-rng.xml"
  end

  def validate
    xsd = Nokogiri::XML::RelaxNG(File.read(@relax_file))
    errors = xsd.validate(@xml).map {|err| err.message}
    if errors.any?
      @errors << I18n.t('template_xml.errors.invalid_xml')
      @errors += errors
    end
    @errors << I18n.t('template_xml.errors.name_is_not_set') if @xml.xpath('/template/name').text.empty?
    @errors
  end

  def self.validate(xmlstr)
    begin
      doc = TemplateXML.new(xmlstr)
    rescue Nokogiri::XML::SyntaxError
      return [I18n.t('template_xml.errors.xml_parser_error')]
    end
    return doc.validate
  end

  def name=(name)
    if @xml.root.nil? || @xml.root.name != 'template'
      @xml.root = @xml.create_element('template')
    end

    if @xml.xpath('/template/name').empty?
      @xml.xpath('/template').first << @xml.create_element('name')
    end

    @xml.xpath('/template/name').first.content = name unless name.blank?
  end

  def name
    doc.xpath('/template/name').text
  end

  def to_xml
    @xml.to_xml
  end
end
