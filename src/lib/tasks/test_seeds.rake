namespace :db do
  namespace :test do
    task :prepare do
      Rake::Task["db:seed"].invoke
    end
  end
end
