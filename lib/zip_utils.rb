require 'fileutils'
require 'zip'

module ZipUtils

  def unzip zipfile_name
    FileUtils.rm_r "./ziptemp" if File.directory?("./ziptemp")
    content = []
    Zip::File.open(zipfile_name) do |zip_file|
      zip_file.each do |entry|
        entry.extract("./ziptemp/#{entry.name}")
        input_stream = entry.get_input_stream
        content << input_stream.read unless input_stream == Zip::NullInputStream
      end  
    end
    content
  end

end