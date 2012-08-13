require 'epubinfo'

class Writer
  def initialize(directory_name, cover_directory_name)
    @cover_directory_name = cover_directory_name

    @csv_file = File.open(directory_name + "/epubs.csv", "w")
    @csv_file.puts 'epubfilename,titles,authors,description,covername,coversize'
  end

  def copy_cover(epub, epub_file_name)
    if epub.cover
      epub.cover.tempfile do |cover|
        cover_path = File.join(@cover_directory_name, epub_file_name + '_' + epub.cover.original_file_name.gsub("/", "_"))
        FileUtils.cp cover.path, cover_path
      end
    end
  end

  def csv(epub, epub_file_name)
    @csv_file << [
        ce(epub_file_name),
        ce(epub.titles.to_s),
        ce(epub.creators.map(&:name).to_s),
        ce(epub.description),
        ce(epub.cover && epub.cover.original_file_name),
      ].join(",")

    epub.cover do |cover|
      @csv_file << "," + ce(cover.content.size.to_s)
    end

    @csv_file << "\n"
  end

  def close
    @csv_file.close
  end

  private

  def csv_escape(string)
    (string || "").gsub(',', '\,').gsub(/\n/,'')
  end
  alias :ce :csv_escape

  def write_cover_name(epub_file_name, epub_cover_file_name)
    epub_file_name + epub.cover.file_name.gsub("/", "_")
  end
end

class ExtractEPUBInfo
  EPUB_PATH = './epubs'
  OUTPUT_PATH = './output'

  def self.run
    puts "Extracting epub info ..."

    directory = File.join(OUTPUT_PATH, Time.now.to_i.to_s)
    cover_directory = File.join(directory, "covers")

    Dir.mkdir(OUTPUT_PATH) unless Dir.exists?(OUTPUT_PATH)
    Dir.mkdir(directory)
    Dir.mkdir(cover_directory)

    writer = Writer.new(directory, cover_directory)

    Dir.foreach(EPUB_PATH) do |epub_file_name|
      if epub_file_name[0] != "." and epub_file_name != 'PUT_YOUR_EPUBS_HERE'
        puts epub_file_name

        epub = EPUBInfo.get(File.join(EPUB_PATH, epub_file_name))

        writer.copy_cover(epub, epub_file_name)
        writer.csv(epub, epub_file_name)
      end
    end

    writer.close
  end
end

ExtractEPUBInfo.run
