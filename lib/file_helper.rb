require 'fileutils'
require 'zip'

class FileHelper
  # true if filepath_or_name ends with one of the formats in Rails.application.config.text_formats
  # see config/text_formats.rb
  def is_text(filepath_or_name)
    fn = filepath_or_name.strip.downcase
    Rails.application.config.text_formats.any? { |ftype| fn.ends_with?(ftype) }
  end

  def write_mode(filepath_or_name)
    if (self.is_text(filepath_or_name))
      return 'w'
    else
      return 'wb'
    end
  end

  # remove pythyon .0 timestamp artifact from filename
  # strips whitespace and lowercases filename
  def rmzero(filename)
    filename.sub('.0', '').strip.downcase
  end

  def not_dot(filename)
    filename != '.' && filename != '..'
  end

  def get_filenames(dir)
    files = []
    Dir.new(dir).each do |fn|
      files.push(fn) if self.not_dot(fn)
    end
    files
  end

  # works for url and filename
  def extract_timestamp(filename)
    filename.split('/').last.split('_').first.split('.').first
  end

  def extract_filename(url)
    url.split('/').last.strip.downcase
  end

  # unique could be a unix timestamp or other unique string
  def make_unique_filename(unique, s)
    "#{unique}_#{s}"
  end

  def make_dir(path)
    unless File.directory?(path)
      FileUtils.mkdir_p(path)
    end
  end

  # https://stackoverflow.com/a/37195592/6826791
  def extract_zip(file, destination, prefix='')
    self.make_dir(destination)
    
    prefix_part = "#{prefix}_" unless prefix == ''

    Zip::File.open(file) do |zip_file|
      zip_file.each do |f|
        
        # if prefix is not specified, the filename will remail unprefixed
        prefixed_filename = "#{prefix_part}#{f.name}"
        
        fpath = File.join(destination, prefixed_filename)

        zip_file.extract(f, fpath) unless File.exist?(fpath)
      end
    end
  end
end