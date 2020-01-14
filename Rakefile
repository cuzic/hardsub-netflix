require 'tmpdir'
require 'zip'
require 'fileutils'
require 'securerandom'
require 'zip'

# $subtitleedit = "C:\\Program Files\\Subtitle Edit\\SubtitleEdit.exe"
$subtitleedit = "SubtitleEdit"
$ffmpeg = "ffmpeg"


# https://stackoverflow.com/questions/9204423/how-to-unzip-a-file-in-ruby-on-rails
def extract_zip(file, destination)
  FileUtils.mkdir_p(destination)

  Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
end

rule '.srt' => '.英語.ttml' do |t|
  Dir.mktmpdir do |dir|
    sh($subtitleedit, "/convert", t.source, "srt", "/outputfolder:#{dir}")
    Dir.glob("#{dir}/*.srt") do |filename|
      FileUtils.cp filename, t.name
      break
    end
  end
end

rule '.sup' => '.日本語.ttml.zip' do |t|
  Dir.mktmpdir do |dir|
    extract_zip(t.source, dir)
    ttml = Dir.glob("#{dir}/*.xml").first
    Dir.mktmpdir do |dir2|
      ruby("ttml2bdnxml.rb", ttml, dir2)
      bdnxml = Dir.glob("#{dir2}/*_bdn.xml").first
      sh($subtitleedit, "/convert", bdnxml, "blu-raysup", "/outputfolder:#{dir2}")
      sup = Dir.glob("#{dir2}/*.sup").first
      FileUtils.cp sup, t.name
    end
  end
end

def ffmpeg(mp4, srt, sup, target)
  filter_complex = [
    "[0:v]subtitles=#{srt.gsub("C:", "")}:force_style='Alignment=6'[v0]", 
    "[1:s][v0]scale2ref[s][v1]",
    "[v1][s]overlay[v]"
  ].join(";")

  args = [
    "-i", mp4,
    "-itsoffset", "5.5",
    "-i", sup,
    "-filter_complex", filter_complex,
    "-map", "[v]",
    "-codec:a", "mp3",
    "-map", "0:a:0",
    "-y"
  ]
  sh $ffmpeg, *args, target
end
rule '_hardsub.mp4' => [ '.mp4', '.srt', '.sup' ] do |t|
  sources = t.sources.map do |filename|
    File.expand_path(filename, __FILE__)
  end
  Dir.mktmpdir do |dir|
    $stderr.puts "creating #{t.name}"
    basename = "#{dir}/#{SecureRandom.alphanumeric}"
    mp4 = "#{basename}.mp4"
    FileUtils.cp(sources[0], mp4)
    srt = "#{basename}.srt"
    FileUtils.cp(sources[1], srt)
    sup = "#{basename}.sup"
    FileUtils.cp(sources[2], sup)
    target = "#{basename}_.mp4"
    ffmpeg(mp4, srt, sup, target)
    FileUtils.cp(target, t.name)
    $stderr.puts "created  #{t.name}"
  end
end

task :default do
  dir = "#{ENV["USERPROFILE"]}\\Videos\\*.mp4"
  Dir.glob(dir.gsub("\\", "/")) do |mp4|
    p mp4
    next if mp4.include?("_hardsub.mp4")
    target = mp4.gsub(".mp4", "_hardsub.mp4")
    Rake::Task[target.encode("UTF-8")].invoke
  end
end
