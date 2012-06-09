#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'csv'
require 'open3'
require 'tempfile'

$:.unshift File.join(File.dirname(__FILE__),'..','..','bioruby-ipcress','lib')
require 'bio-ipcress'

$:.unshift File.join(File.dirname(__FILE__),'..','lib')
require 'amplicon_encyclopaedia'

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
  :encyclopaedia_csv => File.join(File.dirname(__FILE__), '..', 'data','encyclopaedia.csv'),
}
o = OptionParser.new do |opts|
#TODO Fill in usage, description and option parsing below
  opts.banner = "
    Usage: #{SCRIPT_NAME}

    runs Ipcress over the primers in the encyclopaedia.csv,
    and then prints a description of those studies
    that have matching primers.\n"
    
  opts.on("-s", "--sequence", "Path to FASTA file that contains sequences to be tested [required]") do |q|
    options[:fasta_file] = q
  end

  # logger options
  opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") do |q|
    Bio::Log::CLI.trace('error')
  end
  opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") do | name |
    options[:logger] = name
  end
  opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG") do | s |
    Bio::Log::CLI.trace(s)
  end
end
o.parse!
unless options[:fasta_file]
  $stderr.puts o
  exit 1
end
# Setup logging
Bio::Log::CLI.logger(options[:logger]) #bio-logger defaults to STDERR not STDOUT, I disagree
log = Bio::Log::LoggerPlus.new(LOG_NAME)
Bio::Log::CLI.configure(LOG_NAME)

# Convert encyclopaedia to a temporary ipcress file
encyclopaedia = AmpliconEncyclopaedia::CSVDatabase.new(options[:encyclopaedia_csv])
entries_hash = encyclopaedia.entries_hash
publications_hash = encyclopaedia.publications_hash

passable_ipcresses = nil

Tempfile.open('ipcress') do |ipcress|
  entries_hash.each do |identifier, entry|
    if entry.forward_primer.nil? or entry.reverse_primer.nil?
      log.info "Skipping #{entry.inspect} as no primers were detected"
      next
    end
    
    ipcress.puts [
      identifier,
      entry.forward_primer,
      entry.reverse_primer,
      2,
      2000,
    ].join(' ')
  end
  ipcress.close

  command = "ipcress -m 1 #{ipcress.path} #{ARGV[0]}"
  result = nil
  Open3.popen3(command) do |stdin, stdout, stderr|
    result = Bio::Ipcress.parse(stdout.read)
  end

  passable_ipcresses = result.select{|r| r.recalculate_mismatches_from_alignments == [0,0]}
end

passable_ipcresses.sort!{|a,b| a.experiment_name <=> b.experiment_name}

passable_ipcresses.each do |ipcress|
  ae = entries_hash[ipcress.experiment_name]
  pub = publications_hash[ae.identifying_publication_string]
  
  # if ae.pmid == '22092776'
    # log.debug ae
    # log.debug pub
  # end
  puts [
    ae.identifying_publication_string,
    ae.description,
    ae.medline.nil? ? '' : ae.medline.title,
    ae.comments.join(' ** '),
    pub.all_database_accessions.join(' ** '),
  ].join("\t")
end
