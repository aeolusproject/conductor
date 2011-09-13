config = YAML.load_file("#{::Rails.root.to_s}/config/settings.yml")
Aeolus::Image::WarehouseModel.send(:class_variable_set, '@@config', config)
