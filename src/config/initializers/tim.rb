Tim.user_class = "User"
Tim.provider_account_class = "ProviderAccount"
Tim.provider_type_class = "ProviderType"
# Image Factory URL
Tim::ImageFactory::Base.site = "http://localhost:8075/imagefactory"
# FIXME: We should be able to infer these from Routes
Tim::ImageFactory::TargetImage.callback_url = "http://admin:password@localhost:3000/tim/target_images/"
Tim::ImageFactory::ProviderImage.callback_url = "http://admin:password@localhost:3000/tim/provider_images/"

# TODO: remove this once it's fixed on Tim side
[Rails.root].flatten.map { |p|
  Dir[p.join('app', 'decorators', '**', '*_decorator.rb')]
}.flatten.uniq.each do |decorator|
  Rails.application.config.cache_classes ? require(decorator) : load(decorator)
end
