#
# Copyright (C) 2011 Red Hat, Inc.
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

class ProviderAccountObserver < ActiveRecord::Observer
  def after_create(account)
    # FIXME: new boxgrinder doesn't create bucket for amis automatically,
    # for now we create bucket from conductor
    # remove this hotfix when fixed on boxgrinder side
    if account.provider.provider_type_id == ProviderType.find_by_deltacloud_driver("ec2").id
      create_bucket(account)
    end
    account.populate_hardware_profiles
  end

  private

  def create_bucket(account)
    client = account.connect
    bucket_name = "#{account.credentials_hash['account_id']}-imagefactory-amis"
    # TODO (jprovazn): getting particular bucket takes long time (core fetches all
    # buckets from provider), so we call directly create_bucket, if bucket exists,
    # exception should be thrown (actually existing bucket is returned - this
    # bug should be fixed soon)
    #client.create_bucket(:name => bucket_name) unless client.bucket(bucket_name)
    begin
      client.create_bucket('id' => bucket_name)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n  ")
    end
  end
end

ProviderAccountObserver.instance
