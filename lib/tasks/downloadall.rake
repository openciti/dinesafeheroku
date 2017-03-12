require_relative('../dinesafe/downloader')
require_relative('../dinesafe/update_dinesafe')
require 'open-uri'

namespace :get do 

  @all_archives_service = 'https://openciti.ca/cgi-bin/ds/all'
  @ocurl = 'https://openciti.ca/ds/'

  @VERBOSE = true

  # for is_geo column in Archive model
  @XML_CASE = false
  @GEO_CASE = true

  def extract_timestamp_from_filename(filename)
    filename.split('/').last.split('_').first.split('.').first
  end 

  # if status == 200: returns xml, geo arrays of filenames
  # if status != 200: throws exception
  def get_archive_filenames
    downloader = Downloader.new()
    archive_response = downloader.get_data_object(@all_archives_service)
    status = archive_response['status']

    if status == 200
      xml = archive_response['xml']
      geo = archive_response['geo']

      return xml, geo
    else
      raise "Error getting filenames from web service #{@all_archives_service}. status: #{status}\n"
    end
  end 

  #ad administrative helper
  desc "get the archive filenames from openciti.ca helper service"
  task :filenames => :environment do
    begin
      xml, geo = get_archive_filenames
      
      puts "XML"
      puts xml
      puts "\nGEO"
      puts geo
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    end
  end

  # accepts an array of URI's or a single URI
  def process_geo(geo)
    if !geo.kind_of(Array)
      geo = [geo]
    end 
    geo.each do |geo_file|
      puts geo_file
      geo_path = @ocurl + geo_file
      timestamp = extract_timestamp_from_filename(geo_path)
      archive_processed = Archive.where(:filename => geo_file, :processed => true).first
      puts archive_processed
      if archive_processed.blank?
        start_processing = Time.now
        updater = UpdateGeo.new(geo_path, @VERBOSE, timestamp)
        updater.process
        end_processing = Time.now
        record_count = Address.where(:version => timestamp).count
        if Archive.where(:filename => geo_file).blank?
          #insert case 
          puts 'inserting...'
          Archive.where(:startprocessing => start_processing,
                        :endprocessing => end_processing,
                        :count => record_count,
                        :version => timestamp,
                        :processed => true,
                        :is_geo => @GEO_CASE).first_or_create(:filename => geo_file)
        else
          puts 'updating...'
          archive = Archive.where(:filename => geo_file).first
          archive.update(:processed => true,
                          :startprocessing => start_processing,
                          :endprocessing => end_processing,
                          :count => record_count)
        end
      end        
    end
  end 

  # accepts an array of URI's or a single URI
  def process_xml(xml)
    if !xml.kind_of(Array)
      xml = [xml]
    end

    xml.each do |xml_file|
      xml_path = @ocurl + xml_file
      timestamp = extract_timestamp_from_filename(xml_path)

      if Archive.where(:filename => xml_file, :processed => true).blank?
        start_processing = Time.now
        updater = UpdateDinesafe.new(xml_path, @VERBOSE, timestamp)
        updater.process
        end_processing = Time.now
        record_count = Inspections.where(:created_at => timestamp).count
        if Achive.where(:filename => xml_file).blank?
          #insert case 
          Archive.where(:startprocessing => start_processing,
                        :endprocessing => end_processing,
                        :count => record_count,
                        :version => timestamp,
                        :processed => true,
                        :is_geo => @XML_CASE).first_or_create(:filename => xml_file)
        else
          archive = Archive.where(:filename => xml_file).first
          archive.update(:processed => true,
                          :startprocessing => start_processing,
                          :endprocessing => end_processing,
                          :count => record_count)
        end
      end
    end    
  end 

  desc "update xml files"
  task :xml => :environment do
    xml, geo = get_archive_filenames
    process_xml(xml)    
  end

  desc "update geo files"
  task :geo => :environment do
    xml, geo = get_archive_filenames
    process_geo(geo)    
  end

  desc "interactive rake task to process one or more archives or archive groups"
  task :all => :environment do
    xml, geo = get_archive_filenames
    process_geo(geo)
    process_xml(xml)
  end

end