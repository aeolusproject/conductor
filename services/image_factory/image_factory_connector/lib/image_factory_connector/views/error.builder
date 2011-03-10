xml.instruct! :xml, :version => '1.0'
@error.each do |k,v|
  xml.error v
end