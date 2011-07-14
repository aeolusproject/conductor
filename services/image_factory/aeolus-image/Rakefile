require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'
require 'rake/rpmtask'

RPMBUILD_DIR = "#{File.expand_path('~')}/rpmbuild"
RPM_SPEC = "rubygem-aeolus-image.spec"

spec = Gem::Specification.new do |s|
  s.name = 'aeolus-image'
  s.version = '0.0.1'
  s.has_rdoc = true
  s.summary= 'cli for aeolus cloud suite'
  s.description = 'Commandline interface for working with the aeolus cloud management suite'
  s.author = 'Jason Guiditta, Martyn Taylor'
  s.email = 'jguiditt@redhat.com, mtaylor@redhat.com'
  s.license = 'GPL-2'
  s.homepage = 'http://aeolusproject.org'
  s.executables << 'aeolus-image'
  s.files = %w(Rakefile) + Dir.glob("{bin,lib,spec,examples,man}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
  s.add_dependency('nokogiri', '>=0.4.0')
  s.add_dependency('rest-client')
  s.add_dependency('image_factory_console', '>=0.4.0')

  s.add_development_dependency('rspec', '~>1.3.0')
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "aeolus-image Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.libs << Dir["lib"]
end

Rake::RpmTask.new(RPM_SPEC) do |rpm|
  rpm.need_tar = true
  rpm.package_files.include("lib/*")
  rpm.topdir = "#{RPMBUILD_DIR}"
end
