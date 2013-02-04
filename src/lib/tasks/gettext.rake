namespace :gettext do
  def files_to_translate
    Dir.glob("{app,lib,config,locale}/**/*.{rb,haml,mustache}")
  end
end