require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

# Meta -------------------------------
PKG_VERSION = "0.1"
RUBYFORGE_PROJECT = "mockr"
RUBYFORGE_USER = "purcell"


# Coding -------------------------------
desc 'Run Tests'
Rake::TestTask.new :test do |t|
  t.test_files = FileList['test/*.rb']
end


# Sharing -------------------------------
PKG_FILES = FileList["lib/*.rb", "test/*.rb"]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Easy Mock Objects for Ruby."
  s.name = RUBYFORGE_PROJECT
  s.version = PKG_VERSION
  s.requirements << 'none'
  s.require_path = 'lib'
  s.files = PKG_FILES
  s.has_rdoc = true
  s.description = <<-EOF
  MockR is a tiny mock object library inspired by JMock.  Main selling points:
   * Natural and unintrusive syntax
   * Supports the distinction between mocks and stubs
   * Constraint-based mechanism for matching call parameters
  See http://mockr.sanityinc.com/ for more info.
  EOF
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "MockR -- Easy Mock Objects for Ruby"
  rdoc.options << '--line-numbers' << '--inline-source' << '--accessor' << 'cattr_accessor=object'
  #rdoc.rdoc_files.include('README', 'CHANGELOG')
  rdoc.rdoc_files.include('lib/*.rb')
}

desc "Publish the API documentation"
task :publish => [:rdoc] do
  Rake::RubyForgePublisher.new(RUBYFORGE_PROJECT, RUBYFORGE_USER).upload
end

task :dist => [:test, :rdoc, :package]

task :default => [:test]

