require 'pry'
require 'erb'
require 'fileutils'

class Converter
  def initialize(width, height, dir, src_dir, destname, events)
    @width, @height = width, height
    @dir, @src_dir = dir, src_dir
    @destname = destname
    @events = events.to_a
  end

  def self.create(argv)
    ttml = argv.shift
    src_dir = File.dirname(ttml)
    dir = argv.shift

    width, height, events = subtitles(ttml)

    basename = File.basename(File.dirname(ttml), ".ttml")
    destname = "#{File.join(dir, basename)}_bdn.xml"

    self.new(width, height, dir, src_dir, destname, events)
  end

  def self.subtitles(filename)
    body = open(filename, &:read)
    tt = body[%r(<(ns2:)?tt .+?>)]

    extent = %r((?:ns[23]|tts):extent="(?<width>\d+)px (?<height>\d+)px")
    m = tt.match(extent)
    width, height = m.named_captures.values_at("width", "height").map(&:to_i)
    origin = %r((?:ns[23]|tts):origin="(?<x>\d+)px (?<y>\d+)px")
    start = %r(begin="(?<start>[0-9:.]+)")
    finish = %r(end="(?<finish>[0-9:.]+)")
    image = %r(<(?:ns2:)?image src="(?<filename>[^"]+)"\s*/>)

    return width, height, Enumerator.new do |y|
      attrs = Regexp.union(extent, origin, start, finish)
      body.scan(%r(<(?:ns[23]:)?div .+?</(?:ns[23]:)?div>)m) do |div|
        m = div.match(%r(#{attrs}\s+#{attrs}\s+#{attrs}\s+#{attrs}.+?#{image})m)
          y << m.named_captures
      end
    end
  end

  def f(time)
    time.gsub(".", ":").slice(0, 11)
  end

  def delta_x_of(events, sizes)
    events.zip(sizes).flat_map do |ev, (width, _)|
      x = ev["x"].to_i
      [ x, @width - x - width ]
    end.min
  end

  def top_y_of(events)
    events.map do |ev|
      ev["y"].to_i
    end.min
  end

  def bottom_y_of(events, sizes)
    events.zip(sizes).map do |ev, (_, height)|
      ev["y"].to_i + height
    end.max
  end

  def size(delta_x, top_y, bottom_y)
    "#{@width-2*delta_x}x#{bottom_y - top_y}"
  end

  def coordinate(event, delta_x, top_y)
    x = event["x"].to_i
    y = event["y"].to_i
    "+#{x-delta_x}+#{y-top_y}"
  end

  def layout_subtitle(event, delta_x, top_y)
    filename = event["filename"]
    imgname = "#{@src_dir}/#{filename}"
    [imgname, "-repage", coordinate(event, delta_x, top_y)]
  end

  def convert(events)
    sizes = events.map do |ev|
      ev.values_at("width", "height").map(&:to_i)
    end
    delta_x = delta_x_of(events, sizes)
    top_y = top_y_of(events)
    bottom_y = bottom_y_of(events, sizes)

    magick = ["magick", "convert"]
    args = [
      "-size", size(delta_x, top_y, bottom_y),
      "canvas:gray3",
      *events.flat_map {|event| [ "(", *layout_subtitle(event, delta_x, top_y), ")" ] },
      "-layers", "merge",
      "-transparent", "gray3"
    ]
    filename = events.first["filename"]
    converted = "#{@dir}/#{filename}"
    unless File.file?(converted)
      system(*magick, *args, converted)
      # puts [*magick, *args, converted].map{|s| %("#{s}")}.join(" ")
    end

    return delta_x, top_y, bottom_y
  end

  def source(event)
    File.join(@src_dir, event["filename"])
  end

  def dest(event)
    File.join(@dir, event["filename"])
  end

  def update(event, delta_x, top_y, bottom_y)
    event.dup.tap do |ev|
      ev["width"] = @width - 2*delta_x
      ev["height"] = bottom_y - top_y
      ev["x"] = delta_x
      ev["y"] = top_y
    end
  end

  def merge(events)
    if events.size == 1
      event = events.first
      if event["height"].to_i < event["width"].to_i &&
          400 < event["y"].to_i
        FileUtils.cp(source(event), dest(event))
        return event
      end
    end

    delta_x, top_y, bottom_y = convert(events)
    update(events.first, delta_x, top_y, bottom_y)
  end

  def render_event(event)
    <<~EVENT
  <Event InTC="#{f event["start"]}" OutTC="#{f event["finish"]}" Forced="False">
    <Graphic Width="#{event["width"]}" Height="#{event["height"]}" X="#{event["x"]}" Y="#{event["y"]}">#{event["filename"]}</Graphic>
  </Event>
    EVENT
  end

  def render_events(grouped)
    grouped.map do |_, events|
      event = merge(events)
      render_event(event)
    end.join("\n")
  end

  def grouped_events(events)
    events.group_by do |event|
      event.values_at("start", "finish")
    end.sort
  end

  def render
    first_time = @events.first["start"]
    last_time = @events.last["finish"]
    grouped = grouped_events(@events)

    open(@destname, "w") do |f|
      f.puts <<~EOD
<?xml version="1.0" encoding="UTF-8"?>
<BDN Version="0.93" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BD-03-006-0093b BDN File Format.xsd">
  <Description>
  <Name Title="BDN Example" Content=""/>
  <Language Code="eng"/>
  <Format VideoFormat="#{@height}p" FrameRate="23.976" DropFrame="False"/>
  <Events Type="Graphic" FirstEventInTC="#{f first_time}" LastEventOutTC="#{f last_time}" NumberofEvents="#{grouped.count}"/>
  </Description>
      <Events>
      #{render_events(grouped)}
  </Events>
</BDN>
      EOD
    end
  end
end

def main
  converter = Converter.create(ARGV)
  converter.render
end

if $0 == __FILE__
  main
end

