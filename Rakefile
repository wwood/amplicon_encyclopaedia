# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "amplicon_encyclopaedia"
  gem.homepage = "http://github.com/wwood/amplicon_encyclopaedia"
  gem.license = "MIT"
  gem.summary = %Q{A curated collection of primers used in environmental amplicon studies}
  gem.description = %Q{A curated collection of primers used in environmental amplicon studies. It is sometimes difficult to ascertain whether a particular species has not previously been found because primers were not suitably designed, or because the organism was simply not there. AmpliconEncyclopaedia helps answer that question by curating lists of primers used in these studies such that in-silico PCRs can be run on partial, full length, or better yet the entire genome of species of interest.}
  gem.email = "gmail.com after donttrustben"
  gem.authors = ["Ben J Woodcroft"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "amplicon_encyclopaedia #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
