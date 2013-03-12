namespace :gettext do
  def files_to_translate
    Dir.glob("{app,lib,config,locale,db}/**/*.{rb,haml,mustache}")
  end
end