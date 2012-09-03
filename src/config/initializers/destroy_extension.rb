class ActiveRecord::Base
  # this method is used in in controllers where we need to get
  # message why some before_destroy callback failed
  #
  # I'm not entirely sure that it's ideal to use obj.errors to pass
  # errors from before_destroy callbacks, but it allows us to avoid
  # begin-rescue blocks in most of controllers
  def safe_destroy
    destroy
  rescue Aeolus::Conductor::Base::NotDestroyable => ex
    errors.add(:base, ex.message)
    false
  end
end
