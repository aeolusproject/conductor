class ProviderAccountObserver < ActiveRecord::Observer
  def after_create(account)
    # FIXME: new boxgrinder doesn't create bucket for amis automatically,
    # for now we create bucket from conductor
    # remove this hotfix when fixed on boxgrinder side
    if account.provider.provider_type_id == ProviderType.find_by_codename("ec2").id
      create_bucket(account)
    end
    if key = account.generate_auth_key
      account.update_attribute(:instance_key, InstanceKey.create!(:pem => key.pem.first, :name => key.id, :instance_key_owner => account))
    end
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
      client.create_bucket(:name => bucket_name)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n  ")
    end
  end
end

ProviderAccountObserver.instance
