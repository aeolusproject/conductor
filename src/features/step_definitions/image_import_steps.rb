Given /^Image Warehouse is running$/ do
  # Stub the `upload` class method. This saves us from requining
  # Image Warehouse daemon to be running for the tests.
  ImageWarehouseObject.send(:define_method, :upload) { nil }
end
