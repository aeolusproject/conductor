#
# Copyright (C) 2010 Red Hat, Inc.
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

# This service is a very early attempt at integration with the Image Builder, and
# should in no way be considered either stable or production-ready.
# In order to use this service you must have the gem installed for image_builder_console.
# This can be checked out from the image_builder repo (link on deltacloud.org), and built
# locally.  Then keep a terminal open to run this in and run with:
#   ruby image_builder_service.rb

$: << File.join(File.dirname(__FILE__), "../dutils")
require 'dutils'
require "image_builder_console"
require 'logger'


#TODO: Figure out why logger does not work, w or w/o the class below
class Logger
  def format_message(severity, timestamp, progname, msg)
    "#{severity} #{timestamp} (#{$$}) #{msg}\n"
  end
end

class ImageBuilderService
  def initialize()
    @console ||= ImageBuilderConsole.new
    @activebuilds ||= []
    poll
    log = Logger.new(STDOUT)
    log.warn "Service initialized..."
    puts log.inspect
  end

  def check_for_queued
    queue = Image.find(:all, :conditions => {:status => Image::STATE_QUEUED})
    cur_builds = Image.find(:all, :conditions => "build_id IS NOT NULL AND status != 'complete'")
    if queue.size > 0 || cur_builds.size > 0
      puts "========================================"
      puts "Queued Builds: " + queue.size.to_s
      puts "All Incomplete Builds: " + cur_builds.size.to_s
      puts "========================================"
    end
    cur_builds.size > queue.size ? find_orphaned(cur_builds) :
    queue.each {|t|
      build(t)
    }
  end

  def build(descriptor_target)
    #targets.each do |t|
      puts "========================================"
      puts "target: " + descriptor_target.name + ", status: " + descriptor_target.status
      puts "========================================"
      ab = @console.build_image(descriptor_target.template.xml.to_xml, descriptor_target.name)
      if ab
        update_build_list(ab, descriptor_target)
        descriptor_target.build_id = ab.object_id.to_s
        descriptor_target.save!
        puts "========================================"
        puts "Build id saved as: " + descriptor_target.build_id
        puts "========================================"
      end
    #end
  end

  def check_build_num
    @activebuilds.size
  end

  def find_orphaned(cur_builds)
    cur_builds.delete_if do |b|
      @activebuilds.size == 0 ? break :
      @activebuilds.each do |ab|
        b.build_id.eql?(ab[:build_id])
      end
    end
    if cur_builds.size > 0
      puts "========================================"
      puts "There appear to be " + cur_builds.size.to_s + " untracked builds."
      puts "Attempting to get status updates...."
      puts "========================================"
      found = []
      cur_builds.each do |t|
        found << {:ab => @console.find_build(t.build_id),
                  :target => t }
      end
      puts "========================================"
      puts "Retrieved " + found.size.to_s + " builds to update."
      puts "========================================"
      found.each do |f|
        update_build_list(f[:ab], f[:target])
      end
    end
  end

  def update_agg(obj,new_status)
    puts "========================================"
    puts "Getting ar object to update using " + obj[:build].target.inspect + " and " + obj[:ar_id].inspect + " ..."
    puts "========================================"
    idt = Image.find(:first, :conditions => { :name => obj[:build].target.to_s,
                                                              :template_id => obj[:ar_id].to_i })
    puts "========================================"
    puts "Updating with status: " + new_status
    puts "========================================"
    idt.status = new_status
    idt.save!
    puts "========================================"
    puts "database updated!"
    puts "========================================"
  end

  private
  def poll()
      loop do
        check_for_queued
        @activebuilds.delete_if do |ab|
          cur_status = @console.check_status(ab[:build])
          update_agg(ab, cur_status) unless cur_status.eql?(ab[:status])
          puts "========================================"
          puts "Status for target " + ab[:build].target + ": " + cur_status
          puts "Builds in array: " + check_build_num.to_s
          puts "========================================"
          cur_status.eql?("complete")
        end
        sleep 8
      end
  end

  def update_build_list(ab, target)
    @activebuilds <<
          { :ar_id => target.template.id,
            :build => ab,
            :status => target.status,
            :build_id => ab.object_id.to_s
          }
  end
end

ImageBuilderService.new
