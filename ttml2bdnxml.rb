require 'pry'
require 'erb'
require 'fileutils'

def subtitles(filename)
  body = open(filename, &:read)
  tt = body[%r(<(ns2:)?tt .+?>)]

  extent = %r((?:ns[23]|tts):extent="(?<width>\d+)px (?<height>\d+)px")
  m = tt.match(extent)
  $width, $height = m.named_captures.values_at("width", "height").map(&:to_i)
  origin = %r((?:ns[23]|tts):origin="(?<x>\d+)px (?<y>\d+)px")
  start = %r(begin="(?<start>[0-9:.]+)")
  finish = %r(end="(?<finish>[0-9:.]+)")
  image = %r(<(?:ns2:)?image src="(?<filename>[^"]+)"\s*/>)

  Enumerator.new do |y|
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

def layout_subtitle(event)
  filename, x, y = *event.values_at("filename", "x", "y")
  imgname = "#{$src_dir}/#{filename}"
  [imgname, "-repage", "+#{x.to_i-$delta_x}+#{y.to_i-$delta_y}"]
end

def convert(events)
  magick = ["magick", "convert"]
  args = [
    "-size", "#{$width-2*$delta_x}x#{$height-2*$delta_y}",
    "canvas:gray3",
    *events.flat_map {|event| [ "(", *layout_subtitle(event), ")" ] },
    "-layers", "merge",
    "-transparent", "gray3"
  ]
  filename = events.first["filename"]
  converted = "#{$dir}/#{filename}"
  unless File.file?(converted)
    system(*magick, *args, converted)
  end
end

def render_event(event)
  <<~EVENT
  <Event InTC="#{f event["start"]}" OutTC="#{f event["finish"]}" Forced="False">
    <Graphic Width="#{event["width"]}" Height="#{event["height"]}" X="#{event["x"]}" Y="#{event["y"]}">#{event["filename"]}</Graphic>
  </Event>
  EVENT
end

def grouped_events(events)
  events.group_by do |event|
    event.values_at("start", "finish")
  end.sort
end

def merge(events)
  if events.size == 1
    event = events.first
    if event["height"].to_i < event["width"].to_i &&
        400 < event["y"].to_i
      src = File.join($src_dir, event["filename"])
      dest = File.join($dir, event["filename"])
      FileUtils.cp(src, dest)
      return event
    end
  end

  convert(events)
  events.first.dup.tap do |ev|
    ev["width"] = $width - 2*$delta_x
    ev["height"] = $height - 2*$delta_y
    ev["x"] = $delta_x
    ev["y"] = $delta_y
  end
end

def render_events(grouped)
  grouped.map do |_, events|
    event = merge(events)
    render_event(event)
  end.join("\n")
end

def render(events, destname)
  first_time = events.first["start"]
  last_time = events.last["finish"]
  grouped = grouped_events(events)

  open(destname, "w") do |f|
    f.puts <<~EOD
<?xml version="1.0" encoding="UTF-8"?>
<BDN Version="0.93" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BD-03-006-0093b BDN File Format.xsd">
  <Description>
	<Name Title="BDN Example" Content=""/>
	<Language Code="eng"/>
	<Format VideoFormat="#{$height}p" FrameRate="23.976" DropFrame="False"/>
  <Events Type="Graphic" FirstEventInTC="#{f first_time}" LastEventOutTC="#{f last_time}" NumberofEvents="#{grouped.count}"/>
  </Description>
  <Events>
  #{render_events(grouped)}
  </Events>
</BDN>
    EOD
  end
end

def main
  ttml = ARGV.shift
  $src_dir = File.dirname(ttml)
  $dir = ARGV.shift
  events = subtitles(ttml).to_a

  $delta_x = events.flat_map do |ev|
    x = ev["x"].to_i
    width = ev["width"].to_i
    [x, $width - (x+width)]
  end.min - 2
  $delta_y = events.flat_map do |ev|
    y = ev["y"].to_i
    height = ev["height"].to_i
    [y, $height - (y+height)]
  end.min - 2

  basename = File.basename(File.dirname(ttml), ".ttml")
  destname = "#{File.join($dir, basename)}_bdn.xml"
  render(events, destname)
end

if $0 == __FILE__
  main
end

