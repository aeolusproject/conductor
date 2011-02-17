# == Schema Information
# Schema version: 20110207110131
#
# Table name: deployables
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Deployable < ActiveRecord::Base
end
