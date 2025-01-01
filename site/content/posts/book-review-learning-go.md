---
title: "書評: 初めてのGo言語"
date: 2024-02-03T00:00:00+09:00
draft: false
tags: [ golang ]
categories: [ book-review ]

toc: true
related: true
social_share: true
disable_comments: false
---

## 書籍概要

[初めてのGo言語](https://www.oreilly.co.jp/books/9784814400041/)

![初めてのGo言語](/images/book-reviews/learning-go.jpeg)


## モチベーション

Go言語の入門書は一度読んだ事があるのですが少し情報が古かった為、
比較的新し目の情報を得るために、またGo言語の基本をさっと見直すためにも読んでみました。
「初めてのGo」というタイトルですが、対象読者は他の言語でのプログラミング経験があり、
すこしGo言語を知っている程度の人を対象としているようです。

## 読んでみての感想

読み終わっての感想は、Go言語の基本的/標準的な使い方の解説だけでなく、いわゆる「イディオム的な」プログラミングスタイルに則ったプログラミング方法が理解でき非常に良かったです。
写経をしながら読み進めていたのですが、おかしな翻訳もなく、ストレスなく読了できました。
写経、実験をしつつ読み終わるまでにかかった時間は32時間程でした。

ただ、「初めての」とあるように、Go言語の学習の1冊目を想定しているようで、実際の業務レベルで利用できるようになるには、2冊目・3冊目の本を読んだり、実際に開発をしてみたりする必要があると思います。

## よかった点

サンプルコードが多く、実際に書いて動かしながら学ぶ事で、Go言語の「お作法、イディオム」が理解できました。
他の入門書籍だとサンプルコードが少なかったり、言語機能の紹介の為の例が多く現実の開発に使えるようなサンプルコードが少ない事が多いのですが、本書はそういう事はなく、非常に良かったです。

また、日本語訳版の特典として、翻訳者の方によるGo言語の言語機能・文法事項がコンパクトにまとめられていて、チートシート的に利用できるのでざっと見直すのに便利でした。

なお、もう一つの特典でGo言語のまとまったサンプルプログラム集が付属しています。
こちらはGo言語のイディオム、お作法がわかりやすく理解でき、実際の開発の現場で使えるようなプログラムを書くための参考になりました。

あと翻訳者の方が[日本語版のサンプルコード](https://github.com/mushahiroyuki/lgo)を用意していて、詳細にコメントや解説が書かれているので、読み進める上で非常に助かりました。
翻訳のサンプルコードでここまで丁寧に解説されているのは初めて見ました、お値段以上の価値があります。

## いまいちだった点

かなり良い書籍だったので不満は特にないのですが、あえて言うなら並行処理やネットワークプログラミング、テストといったGo言語の特徴的な機能はわりとあっさりとした内容でした。
ただ、本書はGo言語の基礎を学ぶ為の本なので、これは仕方ないのかなと思います。
並行処理やネットワークプログラミングなどのトピックは2冊目、3冊目の書籍でキャッチアップするのが良いでしょう。

## まとめ

Go言語の入門書としては非常に良い書籍だと思います。
サンプルコードも豊富で、1冊目の書籍としてはかなりおすすめです。
また、Go言語の「イディオム」を本書を通して学べたのは（良い意味で）誤算でした。
本書と並行して、Go言語の公式ドキュメントを読んだり、他の書籍を読んだりして、Go言語の基礎をしっかりと学んでみてください。