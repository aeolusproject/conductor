#
# Copyright (C) 2011 Red Hat, Inc.
# Written by Jason Guiditta <jguiditt@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.


require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name = 'image_factory_console'
  s.version = '0.2.0'
  s.has_rdoc = true
  #s.extra_rdoc_files = ['README', 'COPYING']
  s.summary = 'QMF Console for Aeolus Image Factory'
  s.description = s.summary
  s.author = 'Jason Guiditta'
  s.email = 'jguiditt@redhat.com'
  # s.executables = ['your_executable_here']
  s.files = %w(Rakefile) + Dir.glob("{bin,lib,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['lib/**/*.rb'] #'README', 'COPYING',
  rdoc.rdoc_files.add(files)
  #rdoc.main = "README" # page to start on
  rdoc.title = "console Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib'
  t.spec_files = FileList['spec/**/*.rb']
  t.spec_opts = ['--color', '--format nested']
end
