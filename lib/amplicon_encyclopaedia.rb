require 'csv'


module AmpliconEncyclopaedia
  class Publication
    attr_accessor :primer_sets
    
    def all_database_accessions
      primer_sets.collect {|ae|
        [
        ae.genbanks, ae.sra,
        ae.medline.nil? ? nil : ae.medline.pubmed['SI'].strip.split(/\n/).join(', ')
        ]
      }.flatten.reject{|d| d.nil?}
    end
    
    def has_sequences_from?(accessions)
      primer_sets.reject {|ae|
        accessions.select{ |acc|
          all_database_accessions.include?(acc)
        }.empty?
      }
    end
  end
  
  class CSVDatabase
    include Enumerable
    def initialize(path=File.join(File.dirname(__FILE__),'..','data','encyclopaedia.csv'))
      @csv_path = path
    end

    def each
      CSV.foreach(@csv_path, :col_sep => ',', :headers => true) do |row|
        # skip commented out rows
        next if !row[0].nil? and row[0].match(/^\s*\#/)
        
        entry = Entry.new
        i = 0
        [:forward_primer, :reverse_primer].each do |attr|
          # Remove whitespace from the primers
          unless row[i].nil?
            entry.send("#{attr.to_s}=".to_sym, row[i].gsub(/\s/,''))
          end
          i += 1
        end
        [:pmid, :doi, 
          :url, :target, :coordinates, :description,
          :genbanks, :sra
        ].each do |attr, index|
          entry.send("#{attr.to_s}=".to_sym, row[i].strip) unless row[i].nil?
          i += 1
        end
        
        # The comments are all the rest of the columns
        entry.comments = []
        while !(row[i].nil?)
          entry.comments.push row[i].strip unless row[i].nil?
          i += 1
        end
        
        yield entry
      end
    end
    
    # Return a hash with string identifiers corresponding to entries
    # such that the identifiers are unique
    def entries_hash
      hash = {}
      i = 0
      
      each do |entry|
        hash["AE#{i}"] = entry
        i += 1
      end
      return hash
    end
    
    
    def publications_hash
      publications = PublicationCollect.new
      each do |entry|
        publications[entry.identifying_publication_string] ||= Publication.new
        publications[entry.identifying_publication_string].primer_sets ||= []
        publications[entry.identifying_publication_string].primer_sets.push entry
      end
      return publications
    end
  end
  
  class PublicationCollect<Hash
    # Return those publications that encode one or more of the accessions that a given
    def select_by_accessions(accessions)
      select do |publication_id|
        self[publication_id].has_sequences_from?(accessions)
      end
    end
  end

  class Entry
    DEFAULT_PUBMED_CACHE = File.join(File.dirname(__FILE__),'..','data','pubmed')
    
    attr_accessor :forward_primer, :reverse_primer, :pmid, :doi, :url, :target, :coordinates, :description, :genbanks, :sra
    
    attr_accessor :comments
    
    def identifying_publication_string
      return @pmid unless @pmid.nil?
      return @doi unless @doi.nil?
      return @url unless @url.nil?
      return 'some_unidentified_study'
    end
    
    def cache_path
      File.join(DEFAULT_PUBMED_CACHE,"#{pmid}.medline")
    end
    
    def medline
      return nil if pmid.nil?
      @medline ||= Bio::MEDLINE.new(File.open(cache_path).read)
      @medline
    end
    
    def sras
      # Fix SRA accessions, split them up
      return [] if sra.nil?
      
      sra.split(', ').collect do |s|
        if matches = s.match(/([\dA-Z]+)\.\d+/)
          matches[1]
        else
          s
        end
      end
    end
  end
end
