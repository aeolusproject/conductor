class Provider < ActiveRecord::Base
  has_many :cloud_accounts,  :dependent => :destroy
  has_many :flavors,  :dependent => :destroy
  has_many :images,  :dependent => :destroy
  has_many :realms,  :dependent => :destroy
  has_many :portal_pools, :through=>:cloud_accounts

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_presence_of :cloud_type
  validates_presence_of :url

  def connect
    begin
      return DeltaCloud.new(nil, nil, url)
    rescue Exception => e
      #TODO: log or return an exception
      return nil
    end
  end

  def populate_flavors
    flavors = connect.flavors
    # FIXME: this should probably be in the same transaction as provider.save
    self.transaction do
      flavors.each do |flavor|
        ar_flavor = Flavor.new(:external_key => flavor.id,
                               :name => flavor.name ? flavor.name : flavor.id,
                               :memory => flavor.memory,
                               :storage => flavor.storage,
                               :architecture => flavor.architecture,
                               :provider_id => id)
        ar_flavor.save!
      end
    end
  end

  # TODO: implement or remove - this is meant to contain a hash of
  # supported cloud_types to use in populating form, though if we
  # infer that field, we don't need this.
  def supported_types
  end

  protected
  def validate
    if !nil_or_empty(url)
      errors.add("url", "must be a valid provider url") unless valid_framework?
      puts errors.inspect
    end
  end

  private

  def valid_framework?
    connect.nil? ? false : true
  end
end
