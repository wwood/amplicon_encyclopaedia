#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'highline'
require 'gdata/client'  
require 'gdata/http'
require 'gdata/auth'

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
  :download_target => File.join(File.dirname(__FILE__),'..','data','encyclopaedia.csv'),
  :username => 'woodibe', #'ben4spammyspam', #
  :download_url => 
    'https://spreadsheets.google.com/feeds/download/spreadsheets/Export?key='+
    '0AodwtVLmMZJzdEI1Wlg4Tnlra3J2Z09KSTl4NXFXcUE'+
    '&exportFormat=csv'
}
o = OptionParser.new do |opts|
  #TODO Fill in usage, description and option parsing below
  opts.banner = "
    Usage: #{SCRIPT_NAME}
    
    Download amplicon encyclopaedia from google docs into the data directory ...\n"
    
  # Example option
  opts.on("-u", "--username", "username for Google docs [default: #{options[:username]}]") do |f|
    options[:username] = f
  end
  
  opts.on("--sra-list","Print SRA accessions to be download [default: download the Google document encyclopaedia definition]") do
    options[:operation] = :sra
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
if ARGV.length != 0 # Don't accept any arguments
  $stderr.puts o
  exit 1
end
# Setup logging
Bio::Log::CLI.logger(options[:logger]) #bio-logger defaults to STDERR not STDOUT, I disagree
log = Bio::Log::LoggerPlus.new(LOG_NAME)
Bio::Log::CLI.configure(LOG_NAME)


if options[:operation] == :sra
  $:.unshift File.join(File.dirname(__FILE__),'..','lib')
  require 'amplicon_encyclopaedia'
   
  ae = AmpliconEncyclopaedia::CSVDatabase.new
  ae.publications_hash.values.each do |pub|
    pub.primer_sets.each do |pr|
      unless pr.sra.nil?
        puts pr.sras.join("\n")
      end
    end
  end
else
  client = GData::Client::Spreadsheets.new
  client.clientlogin(options[:username], HighLine.new.ask("Google docs password for #{options[:username]}:") {|q| q.echo = false})
  log.info 'logged in. Retrieving document..'
  test = client.get(options[:download_url])
  
  log.info "Retrieved. outputting downloaded csv file to #{options[:download_target]}"
  file = File.new(options[:download_target], "w")  
  file.write test.body
  file.close
  log.info "Complete. File downloaded to #{options[:download_target]}"
end
