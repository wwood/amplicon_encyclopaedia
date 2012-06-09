#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'bio'

$:.unshift File.join(File.dirname(__FILE__),'..','lib')
require 'amplicon_encyclopaedia'

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
  :target_directory => AmpliconEncyclopaedia::Entry::DEFAULT_PUBMED_CACHE,
}
o = OptionParser.new do |opts|
  opts.banner = "
    Usage: #{SCRIPT_NAME} <arguments>
    
    Caches publication-related data for amplicon encyclopaedia entries that have PubMed identifiers\n"
    
  # Example option
  opts.on("-e", "--email EMAIL_ADDRESS", "email to use to query NCBI with [required]") do |f|
    options[:email] = f
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
fail = lambda do $stderr.puts o; exit 1; end
if ARGV.length != 0
  $stderr.puts "ARGV should be zero-length"
  fail.call
end 
if options[:email].nil?
  $stderr.puts "Need to set an email with -e/--email"
  fail.call
end



# Setup logging
Bio::Log::CLI.logger(options[:logger]) #bio-logger defaults to STDERR not STDOUT, I disagree
log = Bio::Log::LoggerPlus.new(LOG_NAME)
Bio::Log::CLI.configure(LOG_NAME)


Bio::NCBI.default_email = options[:email]

Dir.mkdir options[:target_directory] unless File.exist?(options[:target_directory])

AmpliconEncyclopaedia::CSVDatabase.new.each do |entry|
  if entry.pmid
    cachefile_path = entry.cache_path
    if File.exist?(cachefile_path)
      log.info "Skipping download of #{cachefile_path} since it already appears to be downloaded"
    elsif matches = entry.pmid.match(/\s*(\d\d\d\d+)\s*/)
      pubmeds = Bio::PubMed.efetch(matches[1])
      if pubmeds.length != 1
        log.error "Unexpectedly found #{pubmeds.length} results for #{matches[1]}.. skipping"
      else
        pubmed = pubmeds[0]
        File.open(cachefile_path,'w') do |f|
          f.print pubmed
        end
        log.debug "Successfully downloaded and cached #{pubmed.length} charaters into #{cachefile_path}"
      end
    else
      log.error "Unexpected format for PMID in csv file #{entry.pmid}, ignoring it. Found in entry #{entry.inspect}"
    end
  else
    log.debug "Skipping since there doesn't appear to be any PMID: #{entry.identifying_publication_string}"
  end    
end
