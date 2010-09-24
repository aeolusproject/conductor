desc "Rcov code coverage reports"

begin
  require 'rcov/rcovtask'
  require 'spec/rake/spectask'
  require 'cucumber/rake/task'

  task :rcov      => [ 'rcov:all' ]

  namespace :rcov do 
    
    # Use single quotes here so that regexp argument is not munged.
    R_RCOV_AGGREG_FILE    = 'coverage.data'
    
    R_RCOV_EXCLUDE_DIR    = 'lib\/ruby,lib64\/ruby,features,spec,test'
    
    R_RCOV_OUTPUT_DIR     = 'test_coverage'

    R_RCOV_AGGREG_OPTS    = "--aggregate #{R_RCOV_AGGREG_FILE} " +
                            "--text-summary --no-html "

    R_RCOV_BASIC_OPTS     = "--rails  --exclude #{R_RCOV_EXCLUDE_DIR} " 
    
    R_RCOV_FINAL_OPTS     = "--aggregate #{R_RCOV_AGGREG_FILE} "

    # make the output directory an array.
    r_rcov_dir  = R_RCOV_OUTPUT_DIR.scan(/\/\w+|\w+/)

    task :clear do
      rm_f R_RCOV_AGGREG_FILE
      rm_r( R_RCOV_OUTPUT_DIR, :force => true)
    end

    # We build three versioof each task
    #   _single     = stand alone report
    #   _aggregate  = initial aggregate reports
    #   _final      = final aggregate report run after all other aggregates
    [ 'single', 'aggregate', 'final' ].each do |reptype|

      # puts "should see this three times"
      # Set the rcov optiovariables according to report type
      r_rcov_opta = nil                 if reptype == 'single'
      r_rcov_opta = R_RCOV_AGGREG_OPTS  if reptype == 'aggregate'
      r_rcov_opta = R_RCOV_FINAL_OPTS   if reptype == 'final'


      # builds task int_cucumber_X
      Cucumber::Rake::Task.new("int_cucumber_#{reptype}") do |t|
        t.rcov          = true
        t.rcov_opts     =  R_RCOV_BASIC_OPTS.scan(/(--\w+)|([\\|\/|,|\w]*)/)
        t.rcov_opts     << r_rcov_opta
        t.rcov_opts     = [ " --output #{R_RCOV_OUTPUT_DIR}" ]
      end

      # builds task int_rspec_X
      Spec::Rake::SpecTask.new("int_rspec_#{reptype}") do |t|
        t.spec_files    =  FileList['spec/**/*_spec.rb']
        t.rcov          =  true
        t.rcov_dir      =  r_rcov_dir
        t.rcov_opts     =  R_RCOV_BASIC_OPTS.scan(/(--\w+)|([\\|\/|,|\w]*)/)
        t.rcov_opts     << r_rcov_opta
      end
    end

  end

rescue LoadError
end

