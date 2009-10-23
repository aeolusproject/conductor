class CloudAccount < ActiveRecord::Base
  belongs_to :provider
  has_many :portal_pools,  :dependent => :destroy

  # what form does the account quota take?

  # we aren't yet defining the local user object
  # has_many :portal_users


  validates_presence_of :provider_id

  validates_presence_of :username
  validates_uniqueness_of :username, :scope => :provider_id
  validates_presence_of :password

  def connect
    begin
      return DeltaCloud.new(username, password, provider.url)
    rescue Exception => e
      logger.error("Error connecting to framework: #{e.message}")
      logger.error("Backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def self.find_or_create(account)
    a = CloudAccount.find_by_username_and_provider_id(account["username"], account["provider_id"])
    return a.nil? ? CloudAccount.new(account) : a
  end
end
