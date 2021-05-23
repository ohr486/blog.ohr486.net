---
title: "blog移転"
date: 2021-05-23T02:30:27+09:00
draft: false
tags: [ hugo, aws ]
categories: [ tech ]
author: ohr486
---

blogのバックエンドをWordPress@AWS-EC2からhugo@AWS-S3に切り替えました。

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
Start building sites …

                   | EN
-------------------+-----
  Pages            |  7
  Paginator pages  |  0
  Non-page files   |  0
  Static files     | 88
  Processed images |  0
  Aliases          |  1
  Sitemaps         |  1
  Cleaned          |  0

Total in 160 ms
```

デフォルトだとカレント直下の`public`ディレクトリが生成され、そこにファイルが出力されます。

```terminfo
$ ls public
404.html    categories  css         img         index.html  index.xml   js          lib         page        sitemap.xml tags
```

## AWSのセットアップ

### ホスティング&デプロイ

hugoで生成したコンテンツのホスティング方法は、公式サイトの[Hosting&Deployment](https://gohugo.io/hosting-and-deployment/)にまとまっています。
[Netlify](https://gohugo.io/hosting-and-deployment/hosting-on-netlify/)にホスティングするのがおすすめらしいのですが、
自分はAWSの`S3`を使ってホスティングする事にしました。

### S3のセットアップ

当然ですがS3のバケットを作成する必要があります。
自分はterraformでプライベートのAWSのリソースを管理しているので
[s3のtfファイル](https://github.com/ohr486/blog.ohr486.net/tree/master/aws)
を作って`terraform plan & apply`でバケットを作成しました。

### deployment

deploymentの設定は`config.toml`に以下の様に記載しました。

```toml
[deployment]
    [[deployment.targets]]
        name = "blog.ohr486.net"
        URL = "s3://<作成したバケット名>?region=ap-northeast-1"

    [[deployment.matchers]]
        pattern = "^.+\\.(js|css|svg|ttf)$"
        cacheControl = "max-age=31536000, no-transform, public"
        gzip = true

    [[deployment.matchers]]
        pattern = "^.+\\.(png|jpg)$"
        cacheControl = "max-age=31536000, no-transform, public"
        gzip = false

    [[deployment.matchers]]
        pattern = "^sitemap\\.xml$"
        contentType = "application/xml"
        gzip = true

    [[deployment.matchers]]
        pattern = "^.+\\.(html|xml|json)$"
        gzip = true
```

deployment設定を記載したら、

```terminfo
$ hugo deploy --dryRun
```

でdryRun、

```terminfo
$ hugo deploy
```

でデプロイできます。

注意点ですが、作成した記事がドラフト(`draft: true`)の場合、当然deploy対象にならないので、
ドラフト状態を解除(`draft: false`)しておく必要があります。

結果は以下。



## まとめ

WordPressからhugoに切り替えました。
使ってみた感想としては、かなり軽量でコンテンツのジェネレートがちょっぱやなので快適です。
CI化やコメント機能の追加等まだまだやる事は残ってるのですが、一旦記事をポストできるところまでできたので終了。
