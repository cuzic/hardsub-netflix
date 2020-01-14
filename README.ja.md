# 概要

Netflix からダウンロードした動画に英日両方の字幕を
つけた動画を作るスクリプト。

## 入力

 - *.mp4
   - 動画
 -  *.英語.ttml
   - 字幕（英語）
   - Netflix の TimedText 形式
 - *.日本語.ttml.zip
   - 字幕（日本語）

## 出力

 - *_hardsub.mp4
   - 英日両方の字幕を hardsub した動画
   - レンダリング位置
     - 英語： 画面上端
     - 日本語： NetFlix のオリジナルと同じ位置

# 使用方法
## OS
SubtitleEdit を内部的に利用している関係で Windows 10 で検証を実施。

## 利用ソフトウェア
 - 下記を事前にインストール
   - [RubyInstaller 2.7](https://rubyinstaller.org/)
   - [SubtitleEdit](https://www.nikse.dk/subtitleedit)
   - [ffmpeg](http://ffmpeg.org/)
   - [Imagemagick](https://imagemagick.org/index.php)
   - [FlixGrabPlus](https://www.flixgrab.com/)

## 利用方法

### Netflix から動画をダウンロード

FlixGrabPlus を使って、Netflix の動画をダウンロードする。

 - 英語字幕、日本語字幕の両方をダウンロードする
 - %USERPROFILE%\Videos 以下にダウンロードする。

### bundle install

下記を実行して、依存ライブラリを展開

```
bundle install

bundle exec rake # %USERPROFILE%\Videos 以下のすべての動画を hardsub する
```

### 内部の動作

 - SubtitleEdit を使い、 *.英語.ttml を *.srt に変換
 - 添付の Ruby スクリプトを使い、 *.日本語.ttml.zip を *.sup に変換
   - 環境変数 TEMP　以下に zip を展開
   - 画像ファイルを imagemagick を使って、変換
   - SONY BDN XML 形式の *.xml ファイルを生成
   - SubtitleEdit を使い、 *.sup に変換
 - *.mp4 、*.srt、*.sup を ffmpeg を使い、字幕埋め込みの動画を作成

