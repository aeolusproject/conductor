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
    ActiveRecord::Base.logger = @logger
    @whouse = Warehouse::Client.new(@uri)
  end

  def run
    while true
      begin
        @logger.info "***** Runnning warehouse sync"
        # TODO: I disabled template sync - legacy_templates should never
        # be changed by anything else than conductor
        #@logger.info "*** syncing legacy_templates"
        #Template.all.each do |i|
        #  i.safe_warehouse_sync
        #  i.save! if i.changed?
        #end
        @logger.info "*** syncing images"
        LegacyImage.all.each do |i|
          i.safe_warehouse_sync
          if i.changed?
            i.save! rescue @logger.error "failed to save image #{i.uuid}: #{$!.message}"
          end
        end
        @logger.info "*** syncing provider images"
        LegacyProviderImage.all.each do |i|
          i.safe_warehouse_sync
          if i.changed?
            i.save! rescue @logger.error "failed to save image #{i.uuid}: #{$!.message}"
          end
        end
      rescue => e
        @logger.error e.message
        @logger.error "backtrace:\n" + e.backtrace.join("\n   ")
      ensure
        @logger.info "sleep #{@delay}"
        sleep @delay
      end
    end
  end
end
