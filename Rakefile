require 'tmpdir'
require 'zip'
require 'fileutils'
require 'securerandom'
require 'zip'
require 'pry'

# $subtitleedit = "C:\\Program Files\\Subtitle Edit\\SubtitleEdit.exe"
$subtitleedit = "SubtitleEdit"
$ffmpeg = "ffmpeg"
$netflix_dir = ENV.fetch("NETFLIX_VIDEOS",
                         File.join(ENV["USERPROFILE"], "Videos"))

$extensions = {
  "ja" => %w(日本語 Japanese),
  "en" => %w(英語 English),
}

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

def resolution_of(bdnxml)
  body = IO.read(bdnxml)
  height = body[%r(Format VideoFormat="(\d+)p"), 1]
  h = height.to_i
  w = h * 16 / 9
  "#{w}x#{h}"
end

def mktmpdir
  prefix = "d"
  tmpdir = %W(
    HARDSUB_NETFLIX_TEMP
    TMPDIR TMP TEMP USERPROFILE
  ).each do |env|
    break ENV[env] if ENV.key?(env)
  end

  Dir.mktmpdir(prefix, tmpdir) do |dir|
    yield dir.gsub("\\", "/")
  end
end

def convert_ttml(source, format)
  mktmpdir do |dir|
    extract_zip(source, dir)
    ttml = Dir.glob("#{dir}/*.xml").first
    mktmpdir do |dir2|
      ruby("ttml2bdnxml.rb", ttml, dir2)
      bdnxml = Dir.glob("#{dir2}/*_bdn.xml").first
      resolution = "/resolution:#{resolution_of(bdnxml)}"
      outputfolder = "/outputfolder:#{dir2}"
      args = [ bdnxml, format, resolution, outputfolder ]
      sh($subtitleedit, "/convert", *args)
      yield dir2
    end
  end
end

def subtitle_sources(lang, extensions)
  -> (filename) do
    candidates = extensions.map do |ext|
      filename.gsub(/\.#{lang}\..+/, ext)
    end
    candidates.find do |source|
      File.exist?(source)
    end || candidates.first
  end
end

def text_subtitle_sources(lang, extensions)
  exts = extensions.map do |ext|
    ".#{ext}.ttml"
  end
  subtitle_sources(lang, exts)
end

def image_subtitle_sources(lang, extensions)
  exts = extensions.map do |ext|
    ".#{ext}.ttml.zip"
  end
  subtitle_sources(lang, exts)
end

def move_sub_to_target(dir, target)
  Dir.glob("#{dir}/*.{sub,idx}").each do |filename|
    extname = File.extname(filename)
    basename = "#{File.basename(target, ".sub")}#{extname}"
    destname = File.join(File.dirname(target), basename)
    FileUtils.mv filename, destname
  end
end

$extensions.each do |lang, extensions|
  text_sources = text_subtitle_sources(lang, extensions)
  rule ".#{lang}.srt" => text_sources do |t|
    mktmpdir do |dir|
      sh($subtitleedit, "/convert", t.source, "srt", "/outputfolder:#{dir}")
      filename = Dir.glob("#{dir}/*.srt").first
      FileUtils.cp filename, t.name
    end
  end

  image_sources = image_subtitle_sources(lang, extensions)
  rule ".#{lang}.sub" => image_sources do |t|
    convert_ttml(t.source, "VobSub") do |dir|
      move_sub_to_target(dir, t.name)
    end
  end

  rule ".#{lang}.sup" => image_sources do |t|
    convert_ttml(t.source, "Blu-raysup") do |dir|
      filename = Dir.glob("#{dir}/*.sup").first
      FileUtils.cp filename, t.name
    end
  end
end

def hardsub(mp4, srt, sup, target)
  filter_complex = [
    "[0:v]subtitles=#{srt.gsub("C:", "")}:force_style='Alignment=6'[v0]", 
    "[1:s][v0]scale2ref[s][v1]",
    "[v1][s]overlay[v]",
  ].join(";")

  args = [
    "-i", mp4,
    # "-itsoffset", "5.5",
    "-itsoffset", "2",
    "-i", sup,
    "-filter_complex", filter_complex,
    "-map", "[v]",
    "-codec:a", "mp3",
    "-map", "0:a:0",
    "-y",
    # "-ss", "300",
    # "-t", "120"
  ]
  sh $ffmpeg, *args, target
end

rule '_hardsub.mp4' => [ '.mp4', '.en.srt', '.ja.sup' ] do |t|
  sources = t.sources.map do |filename|
    File.expand_path(filename, __FILE__)
  end
  mktmpdir do |dir|
    $stderr.puts "creating #{t.name}"
    basename = "#{dir}/#{SecureRandom.alphanumeric}"
    mp4 = "#{basename}.mp4"
    FileUtils.cp(sources[0], mp4)

    eng = "#{basename}.srt"
    FileUtils.cp(sources[1], eng)

    extname = File.extname(t.sources[2])
    ja = "#{basename}#{extname}"
    FileUtils.cp(sources[2], ja)

    target = "#{basename}_.mp4"
    hardsub(mp4, eng, ja, target)
    FileUtils.mv(target, t.name)
    $stderr.puts "created  #{t.name}"
  end
end

task :hardsub, [:name] do |t, args|
  glob = File.join($netflix_dir, "*#{args[:name]}*.mp4")
  Dir.glob(glob.gsub("\\", "/")) do |mp4|
    next if mp4.include?("_hardsub.mp4")
    target = mp4.gsub(".mp4", "_hardsub.mp4")
    Rake::Task[target.encode("UTF-8")].invoke
  end
end

task :softsub, [:name] do |t, args|
  glob = File.join($netflix_dir, "*#{args[:name]}*.mp4")
  Dir.glob(glob.gsub("\\", "/")) do |mp4|
    next if mp4.include?("_hardsub.mp4")
    target = mp4.gsub(".mp4", ".ja.sub")
    Rake::Task[target.encode("UTF-8")].invoke
    target = mp4.gsub(".mp4", ".en.srt")
    Rake::Task[target.encode("UTF-8")].invoke
  end
end

