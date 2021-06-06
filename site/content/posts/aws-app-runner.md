---
title: "サービスレビュー: AWS App Runner"
date: 2021-05-24T22:12:10+09:00
draft: true
tags: [ aws, app-runner ]
categories: [ tech ]
---

## AWS App Runnerとは

### サービスの概要

AppRunnerはAWSのコンピュート系の新サービスで、ソースコードのリポジトリ又は コンテナイメージからWebアプリを簡単にデプロイすることができます。

AWSでコンテナを運用する場合、これまではECSとEKSしか選択肢が無く、それなりに複雑なリソースをセットアップする必要があったんですが、
AppRunnerを利用する事でネットワーク・ロードバランサー・TLS証明書といった関連リソースを一括でデプロイ可能になります。
なおかつ同時リクエスト数に応じてオートスケールされるのでかなりの手間要らずです。

ただし、ソースコードのリポジトリからアプリをデプロイする場合、今のところランタイムはpython3とnode12のみの対応で、
これ以外のラインタイムを利用したい場合はDockerのコンテナレジストリからデプロイする必要があります。
他のサービスの傾向から察するに、今後対応ランタイムは増えていきそうなので、このあたりはもっと使いやすくなると思います。

### サービスの改善要望

ただ、まだリリースしたてのサービスなので気に入らない/改善して欲しいポイントはちょくちょくあるので、
このあたりはぜひAWSに対応してもらいたい所存です。

あげるとキリがないんですが、特に気なっているのは以下です。

(注意) この情報は2021/6時点のAppRunnerの仕様についての要望です。将来的には改善が進み課題は解消されると思いますので、
その前提で読んでください。

* プライベートVPCとの通信ができず、DBをパブリックなVPCに配置せざるをえないので運用しづらい
* WAFのインテグレーションができない
* サイドカーでログを転送するみたいな事はできない(CloudWatchLogsにはログは吐かれるが、費用的にお高くなりそう)
* (例えばNewRelicの様なAPMの有効化等の)特定のプロセス(Pod?Task?)にのみ環境変数や設定を変える仕組みがない
* 設定できるCPU/Memoryのバリエーションが少ない
* (RailsのSidekiqなどの)バックグラウンドで動かすバッチやタスクスケジューラーに適用できない

WAFやログ周りの転送、プライベートVPCとの通信については、運用上欲しい機能なので辛いところです。
またある程度の規模のアプリだと非同期処理、バッチ処理の機構を備えている物が多いんですが、
AppRunnerはHTTP通信を処理するのに特化している為、現状だとAppRunner以外のサービスにこれらを乗せる必要がありそうです。

[AppRunnerのロードマップ](https://github.com/aws/apprunner-roadmap/issues)を見る感じ、
大体の課題感は認知されているようなので今後の改善を待ちましょう。

まだまだ改善ポイントが多いものの、そこそこの数のアプリ/サービスを運用・管理する身としては、うまく利用する事で運用負荷軽減がかなり見込めそうで期待大です。
GCPのCloudRunの有望な対抗馬でしょう。

## セットアップ

`Hello,World!`を動かすだけなら[WORKSHOP](https://www.apprunnerworkshop.com/)の通りにやれば簡単にできるのと、
動かしてみた系の記事が既にいくつかあるので、このpostではもう少し現実に近いケースで試してみました。

### 実行するアプリ

RailsアプリをAppRunnerで動かしてみるケースを想定して動かしてみました。
また、バックエンドはAurora/MySQLを利用しています。
2021/6時点ではAppRunnerはRubyランタイムに対応していないのでDockerイメージをECRにpushして、レジストリからデプロイを行う方式で進めます。

AppRunnerの実行に必要な準備は以下です。

* 関連AWSリソースの作成
* RailsアプリのDockerイメージの作成
* AppRunnerサービスの作成

### 関連AWSリソースの作成

#### ECR

Rubyランタイムで動すので、コンテナイレジストリが必要です。
今のところECRのみ対応しているようですので、ECRのリソースを作成します。

```terraform
# terraform
resource "aws_ecr_repository" "blog_sample_app_runner" {
  name                 = "blog-sample-app-runner"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

#### RDS/Aurora

AppRunnerからRDSを参照する際、DBのインスタンスはPublicなサブネット内に配置する必要があります。
AppRunnerが実行するコンテナはAWSの内部的なネットワーク内で動作する為、
直接Privateなサブネットに通信をかける事ができず、
その為、DBインスタンスをPublicなサブネット内に配置せざるを得ないのが現状です。

これはつまり、DBをインターネットに晒す必要があるという事です。
セキュリティグループ/FireWallがあるとはいえ、セキュリティ的に懸念が大きいです。

この問題は(少なくとも私にとっては)かなり致命的で、プロダクション導入の最大の障壁だと感じました。
[ロードマップのissue](https://github.com/aws/apprunner-roadmap/issues/1)にもかなりのリアクションがあるので、
AWS側の対応を待ちましょう。

ちなみにですが、Aurora Serverlessは[仕様上](https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/AuroraUserGuide/aurora-serverless.html#aurora-serverless.requirements)、
VPC外からアクセスすることはできません。
ですのでAppRunnerからは利用できませんでした、残念。

```terraform
# terraform
```


### RailsアプリのDockerイメージの作成

RailsアプリのDockerイメージを作成する際、気になったポイントとしては以下です。

* REPL
* プロセス設計
* 環境変数の注入
* ログファイルの出力
* Migration

#### REPL

Railsアプリを運用する際、運用中の(サーバー|Pod|コンテナ)にアクセスして対話型のRailsコンソールを立ち上げてデバッグする事はよくあります。
[ECS Exec](https://aws.amazon.com/jp/blogs/news/new-using-amazon-ecs-exec-access-your-containers-fargate-ec2/)の様に、
実行中のコンテナに対して`docker exec`する手段がないのでこのあたりはAWSに是非対応してもらいたい所です。

#### プロセス設計

Railsはアプリケーションサーバーしか提供しないので、nginxなりApacheなりのwebサーバーが必要になります。
開発環境程度ならwebサーバー無しでも問題ないんですが、本番環境での運用時には以下の様な事をしたいケースがあります。

* リクエストのバッファリング
* 静的コンテンツのトラフィックを直接返却
* 静的リダイレクト

また、後述するログファイルの転送の為にfluentdやfluentbitといったログのエクスポーターも同様に必要です。

AppRunnerの構造上、Rails以外のプロセスも1コンテナに同居させる必要がある為、
wrapperスクリプトを作成してその中で複数のプロセスを起動・スーパバイズし、
このスクリプトをコンテナのメインプロセスとして実行させる必要があります。

ただしこの方法は[1コンテナ1アプリパッケージ](https://cloud.google.com/architecture/best-practices-for-building-containers?hl=ja)
のベストプラクティスに反するもので、1つのコンテナで多くの事をやりすぎている為、
システムが複雑になりすぎる可能性があります。
サイドカーパターンを実現する仕組みがAppRunnerに追加されるのを待ちましょう。

なおソースコードからAppRunnerを起動させる場合は、ベースになっているランタイムの[AmazonLinuxのDockerイメージ](https://hub.docker.com/_/amazonlinux)
に対して、起動時のコマンドの中でnginxやfluentdといった必要なミドルウェアをインストールする必要があります。
頑張ればやれなくはないのですが、素直に必要なミドルウェアをインストールしたDockerイメージをECRにpushして使う方が良いでしょう。


#### 環境変数の注入

コンテナに環境変数を渡す方法としては以下の2つあります。

* Dockerfileに記述
* AppRunnerのサービス設定で環境変数を指定

どちらが優先されるかは後述します。



#### ログファイルの出力

AppRunnerのログはCloudWatchに吐かれます。
コンテナの標準出力の内容がそのまま出力されるのですが、
(要確認)

KPIログやユーザーの操作履歴等、ログの種類別に別々に処理をしたい場合は
全て同じ出力先に出力されると運用上困ることがあります。

ECS,EKS,EC2でアプリを運用する場合は、それぞれログの種類別にログファイルを出力し、
それをfluentd、fluentbit等のエクスポーターで転送すれば事足りますが、
AppRunnerの場合ですと





#### Migration





#### Dockerfile




```Dockerfile

```




### AppRunnerサービスの作成

必要な情報がそろったのでAppRunnerサービスを作成します。
注意点として、サービス設定で指定するIPポートをDockerfileでEXPOSEしたIPポートに合わせるようにしてください。

```terraform
# terraform
resource "aws_apprunner_service" "blog_sample_app_runner" {
  service_name = "blog-sample-app-runner"
  source_configuration {
    image_repository {
      image_configuration {
        port = "3000" # DockerfileのEXPOSEに合わせる
      }
      image_identifier      = "${aws_ecr_repository.blog_sample_app_runner.repository_url}:latest"
      image_repository_type = "ECR"
    }
  }
  instance_configuration {
    cpu    = 1024 # 1024|2048|(1|2) vCPU
    memory = 2048 # 2048|3072|4096|(2|3|4) GB
  }
}
```


## スケーリングの確認


## 費用試算





## まとめ




## 参考情報

* [新機能 – AWS App Runner: スケーラブルで安全なウェブアプリケーションをコードから数分で作成](https://aws.amazon.com/jp/blogs/news/app-runner-from-code-to-scalable-secure-web-apps/)
* [AWS App Runner のご紹介](https://aws.amazon.com/jp/blogs/news/introducing-aws-app-runner/)
* [AWS APP RUNNER WORKSHOP](https://www.apprunnerworkshop.com/)
* [AWS App Runner Documentation](https://docs.aws.amazon.com/en_us/apprunner/)
* [Terraform AWS Provider doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [AWS App Runner Roadmap](https://github.com/aws/apprunner-roadmap)
* [AWS Containers Roadmap](https://github.com/aws/containers-roadmap)
* [コンテナ構築のおすすめの方法](https://cloud.google.com/architecture/best-practices-for-building-containers?hl=ja)

