# 概要

FlixGrab+ を用いて Netflix からダウンロードした
動画から英日両方の字幕をつけた動画を作るスクリプト

## 作成理由

 - Language Leaning with Netflix が話題
   - [Free “Language Learning with Netflix” extension makes studying Japanese almost too easy](https://soranews24.com/2020/01/12/free-language-learning-with-netflix-extension-makes-studying-japanese-almost-too-easy/)
   - [Netflixの字幕を英和同時に表示させて英語の勉強に役立ちそうなChrome拡張まとめ](https://gigazine.net/news/20180820-netflix-multi-subtitle/)

 - Chrome 拡張として動作。スマホ（Android）では使えず
 - スマホで使いたかった
 - 英日両方の字幕を埋め込んだ動画の生成スクリプトを作成
 - MX Player 等を使って、カンタンに巻き戻し等ができ、便利

## 入力

 - *.mp4
   - 動画本体
 - *.英語.ttml
   - 字幕（英語）
   - Netflix の TimedText 形式
 - *.日本語.ttml.zip
   - 字幕（日本語）

これらファイルは、 [FlixGrab+](https://www.flixgrab.com/) を
使って、 Netflix からダウンロード

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
   - [FlixGrab+](https://www.flixgrab.com/)

## 利用方法

### Netflix から動画をダウンロード

[FlixGrab+](https://www.flixgrab.com/) を使って、Netflix の動画をダウンロードする

 - 英語字幕、日本語字幕の両方をダウンロードする
 - %USERPROFILE%\Videos 以下にダウンロードする

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

