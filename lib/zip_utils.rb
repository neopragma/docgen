require 'fileutils'
require 'zip'
require_relative "./settings"

module ZipUtils

  def unzip zipfile_name
    temp_dirname = @settings['ziptemp']
    FileUtils.rm_r temp_dirname if File.directory?(temp_dirname)
    content = []
    Zip::File.open(zipfile_name) do |zip_file|
      zip_file.each do |entry|


puts "extracting entry #{temp_dirname}/#{entry.name}"

        entry.extract("#{temp_dirname}/#{entry.name}")


puts "after extract call"

        input_stream = entry.get_input_stream
        content << input_stream.read unless input_stream == Zip::NullInputStream
      end  
    end
    content
  end

  def zip source_dirname, target_filename
    FileUtils.rm_f target_filename
    entries = Dir.entries(source_dirname); entries.delete("."); entries.delete("..")
    io = Zip::File.open(target_filename, Zip::File::CREATE);
    writeEntries(source_dirname, entries, "", io)
    io.close();
  end

  def zip_entries zipfile_name
    entry_names = []
    Zip::File.open(zipfile_name) do |zip_file|
      zip_file.each do |entry|
        entry_names << entry.name
      end
    end
    entry_names
  end

  private

  def writeEntries(source_dirname, entries, path, io)
    entries.each { |e|
      zipFilePath = path == "" ? e : File.join(path, e)
      diskFilePath = File.join(source_dirname, zipFilePath)
      if  File.directory?(diskFilePath)
        io.mkdir(zipFilePath)
        subdir =Dir.entries(diskFilePath); subdir.delete("."); subdir.delete("..")
        writeEntries(source_dirname, subdir, zipFilePath, io)
      else
        io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read())}
      end
    }
  end

end