begin
  require 'cucumber/rake/task'

  namespace :cucumber do
    Cucumber::Rake::Task.new({:junit => ['db:test:prepare','db:seed']}, 'Run features via junit') do |t|
      t.fork = true # You may get faster startup if you set this to false
      t.profile = 'junit'
    end
  end

rescue LoadError
  desc 'cucumber rake task not available (cucumber not installed)'
  task :cucumber do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end
