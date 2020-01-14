require 'pry'
require 'erb'

def subtitles(filename)
  body = open(filename, &:read)
  $dir = File.dirname(filename)

  extent = %r((?:ns[23]|tts):extent="(?<width>\d+)px (?<height>\d+)px")
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
  time.gsub(".", ":")[0..-2]
end

def layout_subtitle(event)
  filename, x, y = *event.values_at("filename", "x", "y")
  imgname = "#{$src_dir}/#{filename}"
  [imgname, "-repage", "+#{x}+#{y}"]
end

def convert(events)
  magick = ["magick", "convert"]
  args = [
    "-size", "1920x1080",
    "canvas:purple",
    *events.flat_map {|event| [ "(", *layout_subtitle(event), ")" ] },
    "-layers", "merge",
    "-transparent", "purple"
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
    <Graphic Width="1920" Height="1080" X="0" Y="0">#{event["filename"]}</Graphic>
  </Event>
  EVENT
end

def grouped_events(events)
  events.group_by do |event|
    event.values_at("start", "finish")
  end.sort
end

def render_events(grouped)
  grouped.map do |_, evs|
    convert(evs)
    render_event(evs.first)
  end.join("\n")
end

def main
  ttml = ARGV.shift
  $src_dir = File.dirname(ttml)
  events = subtitles(ttml).to_a
  first_time = events.first["start"]
  last_time = events.last["finish"]
  grouped = grouped_events(events)

  basename = File.basename(File.dirname(ttml), ".ttml")
  $dir = ARGV.shift
  open("#{$dir}/#{basename}_bdn.xml", "w") do |f|
    f.puts <<~EOD
<?xml version="1.0" encoding="UTF-8"?>
<BDN Version="0.93" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BD-03-006-0093b BDN File Format.xsd">
  <Description>
	<Name Title="BDN Example" Content=""/>
	<Language Code="eng"/>
	<Format VideoFormat="1080p" FrameRate="23.976" DropFrame="False"/>
  <Events Type="Graphic" FirstEventInTC="#{f first_time}" LastEventOutTC="#{f last_time}" NumberofEvents="#{grouped.count}"/>
  </Description>
  <Events>
  #{render_events(grouped)}
  </Events>
</BDN>
    EOD
  end
end

if $0 == __FILE__
  main
end

