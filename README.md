# hardsub-netflix

hardsub/softsub downloaded netflix mp4 files with dual subtitles

# how to use

## requirement

- OS: Windows
  - because SubtitleEdit is written in C#
- [RubyInstaller 2.7](https://rubyinstaller.org/)
- [SubtitleEdit](https://www.nikse.dk/subtitleedit)
- [ffmpeg](http://ffmpeg.org/)
- [Imagemagick](https://imagemagick.org/index.php)
- [FlixGrab+](https://www.flixgrab.com/)
  - Netflix Downloader!

## usage

### First, download mp4 by FlixGrab+

you have to download mp4 by [FlixGrab+](https://www.flixgrab.com/)

 - you have to choose subtitle correctly
 - this tool only accept one text subtitle and one picture-based subtitle
 - the author downloads
   - English CC : text-based subtitle
   - Japanese : picture-based subtitle
 - the mp4 files are stored in %USERPROFILE%\Videos
   - or %NETFLIX_VIDEOS% environment variable if defined

### Second, bundle install

```
bundle install
```

### Third, hardsub or softsub the mp4s.

- please make sure the downloaded mp4 files in %USERPROFILE%\Videos folder
  - or %NETFLIX_VIDEOS%

for hardsub

```
rake harsub[your-movie-title]
```

for softsub

```
rake softsub[your-movie-title]
```

### Last, Enjoy them!

you can find in the same folder

 - `*_hardsub.mp4` files for hardsub
 - `*.srt` , `*.ja.idx`, `*.ja.sub` files for softsub
