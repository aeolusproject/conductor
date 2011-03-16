Factory.define :template do |i|
  i.sequence(:name) { |n| "template#{n}" }
  i.platform 'fedora13'
  i.after_build do |tpl|
    if tpl.respond_to?(:stub!)
      tpl.stub!(:upload).and_return(true)
      tpl.stub!(:delete_in_warehouse).and_return(true)
    end
  end
end
