---
title: "blog移転"
date: 2021-05-23T02:30:27+09:00
draft: true
tags: [ hugo, aws ]
categories: [ tech ]
author: ohr486
---

blogのバックエンドをWordPress@AWS-EC2からhugoに切り替えました。

WordPressはバージョンアップやプラグインの更新が煩雑なのと
MySQLのバックアップ・管理が手間だったので、
hugoに切り替えることでこれらが不要となり、かなり満足です。

hugoのセットアップとアップロードの手順をまとめておきます。

## hugoのセットアップ

### インストール

自分の生活環境はMacなんで`homebrew`でhugoをインストールしました。

```terminfo
$ brew install hugo
```

### サイトの作成

hugoをインストールすると、`hugo`コマンドが利用できるようになります。
`hugo new site <ディレクトリ名>`はサイトを構築するのに必要最低限の設定とディレクトリを作成します。

```terminfo
$ hugo new site my_site
Congratulations! Your new Hugo site is created in /path/to/my_site.

Just a few more steps and you're ready to go:

1. Download a theme into the same-named folder.
   Choose a theme from https://themes.gohugo.io/ or
   create your own with the "hugo new theme <THEMENAME>" command.
2. Perhaps you want to add some content. You can add single files
   with "hugo new <SECTIONNAME>/<FILENAME>.<FORMAT>".
3. Start the built-in live server via "hugo server".

Visit https://gohugo.io/ for quickstart guide and full documentation.
```

### テーマの適用

hugoはかなり多くのテーマがあるので、[Hugo Themes](https://themes.gohugo.io/)から好みのテーマをピックアップしました。
自分は[uBlogger](https://themes.gohugo.io/ublogger/)にしています。

適用方法は[テーマのインストール手順](https://ublogger.netlify.app/theme-documentation-basics/#2-installation)の通り、以下を実行。

```terminfo
$ cd /path/to/my_site
$ git submodule add https://github.com/upagge/uBlogger.git themes/uBlogger
```

適用はこれだけなんで、かなり簡単です。

### 基本設定

hugoで生成したサイトの設定ファイルは、ディレクトリ直下のconfig.tomlです。
詳細な設定内容は[こちら](https://ublogger.netlify.app/theme-documentation-basics/#basic-configuration)を参照してください。

最終的に、こんな感じに落ち着きました。

```toml
baseURL = "https://blog.ohr486.net/"
languageCode = "ja"
title = "ohr486's blog"

# この設定を入れないと、サマリが長くなりすぎてしまう
# CJK=Chinese,Japanese,Koreanの略らしい、しらなかった
hasCJKLanguage = true

# テーマ
theme = "uBlogger"

[params]
    # uBloggerのバージョン、gitのsubmoduleでインストールしたので対象のタグに合わせている
    version = "2.0.X"

    [params.page]
        # SNSボタンはTwitterとFacebookを指定
        [params.page.share]
            enable = true
            Twitter = true
            Facebook = true

# ヘッダに記事一覧、タグ、カテゴリメニューを追加
[menu]
    [[menu.main]]
        identifier = "posts"
        name = "Posts"
        url = "/posts/"
        weight = 1
    [[menu.main]]
        identifier = "tags"
        name = "Tags"
        url = "/tags/"
        weight = 2
    [[menu.main]]
        identifier = "categories"
        name = "Categories"
        url = "/categories/"
        weight = 3

[markup]
    [markup.highlight]
        codeFences = true
        guessSyntax = true
        # uBloggerのテーマを利用する際は必ずnoClassesをfalseにする必要があります
        noClasses = false
```

### 記事の作成

記事を追加する場合はhugoコマンドを使って以下の様に実行します。

```terminfo
$ hugo new <ディレクトリ名>/<記事名>.md
```

このコマンドでcontent配下の指定したディレクトリにmdファイルが作成されます。
自分は設定ファイルで記事のパスを`/posts/`としているのでディレクトリ名は`posts`にしました。

### ローカルサーバーの起動

作成した記事は、`hugo server`で起動したテストサーバーで確認できます。
よく利用するオプションは以下です。

オプション | 効果
-----------| ----
-w | ファイルの変更を自動検知
-D | ドラフト記事(draft=true)も対象にしてページを作成
--disableFastRender | キャッシュを無効化
-F | 未来の日付のページも作成

以下の様にテストサーバーを起動して、`http://localhost:1313`にアクセスするとサイトが確認できます。

```terminfo
$ hugo server -w -D --disableFastRender -F
```

### コンテンツ生成

テストサーバーで問題なければ`hugo`コマンドで静的なHTMLファイルを出力できます。

```terminfo
$ hugo

```

## AWSのセットアップ


## Deploy Pipelineの設定


## まとめ
