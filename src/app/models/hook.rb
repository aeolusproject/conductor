class Hook < ActiveRecord::Base
  validates_presence_of :uri
  validates_presence_of :version
end
