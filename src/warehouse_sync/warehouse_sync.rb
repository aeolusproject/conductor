$: << File.join(File.dirname(__FILE__), "../dutils")

require 'rubygems'
require 'dutils'
require 'warehouse_client'

class WarehouseSync
  class NotFoundError < Exception;end

  def initialize(opts)
    @uri = opts[:uri]
    @delay = opts[:delay] || 10*60
    @logger = opts[:logger]
    @whouse = Warehouse::Client.new(@uri)
  end

  def run
    while true
      begin
        @logger.debug "---------------------------------------"
        pull_templates
        pull_images
        pull_provider_images
      rescue => e
        @logger.error e.message
        @logger.error "backtrace:\n" + e.backtrace.join("\n   ")
      ensure
        @logger.debug "sleep #{@delay}"
        sleep @delay
      end
    end
  end

  def pull_templates
    @logger.debug "*** Getting templates"
    @whouse.bucket('templates').objects.each do |bucket_obj|
      safely_process(bucket_obj) do |obj|
        attrs = obj.attrs([:uuid])
        #tpl = Template.find_by_uuid(attrs[:uuid]) || Template.new(:uuid => attrs[:uuid])
        unless tpl = Template.find_by_uuid(attrs[:uuid])
          raise NotFoundError, "Template with uuid #{attrs[:uuid]} not found"
        end
        tpl.xml = obj.body
        tpl.update_from_xml
        update_changes(tpl)
      end
    end
  end

  def pull_images
    @logger.debug "*** Getting images"
    @whouse.bucket('images').objects.each do |bucket_obj|
      safely_process(bucket_obj) do |obj|
        attrs = obj.attrs([:uuid, :target, :template])
        #img = Image.find_by_uuid(attrs[:uuid]) || Image.new(:uuid => attrs[:uuid])
        unless img = Image.find_by_uuid(attrs[:uuid])
          raise NotFoundError, "image with uuid #{attrs[:uuid]} not found"
        end
        unless attrs[:target]
          raise "target uuid is not set"
        end
        unless ptype = ProviderType.find_by_codename(attrs[:target])
          raise "provider type #{attrs[:target]} not found"
        end
        unless attrs[:template]
          raise "template uuid is not set"
        end
        unless tpl = Template.find_by_uuid(attrs[:template])
          raise "Template with uuid #{attrs[:template]} not found"
        end
        img.provider_type_id = ptype.id
        img.template_id = tpl.id
        update_changes(img)
      end
    end
  end

  def pull_provider_images
    @logger.debug "*** Getting provider images"
    @whouse.bucket('provider_images').objects.each do |bucket_obj|
      safely_process(bucket_obj) do |obj|
        attrs = obj.attrs([:uuid, :image, :icicle, :target_identifier])
        # we don't allow create non-existing ProviderImage in conductor because
        # we don't know provider_id (provider attribute contains only url or
        # string which is not unique in conductor)
        unless pimg = ProviderImage.find_by_uuid(attrs[:uuid])
          raise NotFoundError, "provider image with uuid #{attrs[:uuid]} not found"
        end
        unless attrs[:image]
          raise "image uuid is not set"
        end
        unless img = Image.find_by_uuid(attrs[:image])
          raise "image with uuid #{attrs[:image]} not found"
        end
        unless attrs[:icicle]
          raise "icicle uuid is not set"
        end
        pimg.image_id = img.id
        pimg.icicle = pull_provider_image_icicle(attrs[:icicle])
        pimg.provider_image_key = attrs[:target_identifier]
        update_changes(pimg)
      end
    end
  end

  private

  def pull_provider_image_icicle(uuid)
    @logger.debug "  getting provider image icicle with uuid #{uuid}"
    begin
      whouse_icicle = @whouse.bucket('icicles').object(uuid)
      icicle = Icicle.find_by_uuid(uuid) || Icicle.new(:uuid => uuid)
      icicle.xml = whouse_icicle.body
      icicle.uuid = uuid
      update_changes(icicle)
      icicle
    rescue
      @logger.debug "  skipping image icicle with uuid #{uuid}: #{$!.message}"
      nil
    end
  end

  def safely_process(obj)
    begin
      yield obj
    rescue NotFoundError => e
      @logger.error "Skipping #{obj.key} - not found in DB"
    rescue => e
      @logger.error "Error while processing #{obj.key} (skipping): #{e.message}"
      @logger.error e.backtrace.join("\n   ")
    end
  end

  def update_changes(obj)
    if obj.new_record?
      @logger.debug "#{obj.class.class_name} #{obj.uuid} is not in DB, saving"
      obj.save!
    elsif obj.changed?
      @logger.debug "#{obj.class.class_name} #{obj.uuid} has been changed:"
      log_changes(obj)
      obj.save!
    else
      @logger.debug "#{obj.class.class_name} #{obj.uuid} is without changes"
    end
  end

  def log_changes(obj)
    obj.changed.each do |attr|
      @logger.debug "old #{attr}: #{obj.send(attr + '_was')}"
      @logger.debug "new #{attr}: #{obj[attr]}"
    end
  end
end
