---
title: "サービスレビュー: AWS App Runner"
date: 2021-06-06T22:12:10+09:00
draft: false
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

* Railsアプリの作成
* 関連AWSリソースの作成
* RailsアプリのDockerイメージの作成
* AppRunnerサービスの作成

### Railsアプリの作成

ソースコードは[こちら](https://github.com/ohr486/blog-sample-aws-app-runner/tree/master/app)にupしました。
単純なRailsアプリで以下の機能を持ちます。

* `/info/cpu`で実行環境のCPU情報を出力
* `/info/mem`で実行環境のメモリ情報を出力
* `/users`でusersテーブルに対するCRUD処理

### 関連AWSリソースの作成

必要なAWSリソースはterraformで作成しています。
ソースコードは[こちら](https://github.com/ohr486/blog-sample-aws-app-runner/tree/master/aws)です。

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
resource "aws_rds_cluster" "blog_sample_db" {
  cluster_identifier      = "blog-sample-db"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.07.1"
  availability_zones      = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  database_name           = "blog_sample"
  master_username         = "admin"
  master_password         = "password"
  backup_retention_period = 1
  preferred_backup_window = "07:00-09:00"
  port                    = 3306
  skip_final_snapshot     = true
  db_subnet_group_name    = "ohr486base-public"      # SET YOUR DB SUBNET NAME
  vpc_security_group_ids  = ["sg-0b8cb29c69dc394e6"] # SET YOUR VPC SECURITY GROUP IDS

  tags = {
    Name = "blog-sample"
  }
}

resource "aws_rds_cluster_instance" "blog_sample_db1" {
  identifier               = "blog-sample-db-1"
  instance_class           = "db.t3.small"
  cluster_identifier       = aws_rds_cluster.blog_sample_db.id
  engine                   = aws_rds_cluster.blog_sample_db.engine
  engine_version           = aws_rds_cluster.blog_sample_db.engine_version
  db_subnet_group_name     = aws_rds_cluster.blog_sample_db.db_subnet_group_name

  tags = {
    Name = "blog-sample-db-1"
  }
}
```

#### AppRunner実行の為のIAMRole

```terraform
# terraform
resource "aws_iam_role" "blog_sample_app_runner" {
  name = "blog-sample-app-runner"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "build.apprunner.amazonaws.com",
          "tasks.apprunner.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "blog_sample_app_runner" {
  role       = aws_iam_role.blog_sample_app_runner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}
```

### RailsアプリのDockerイメージの作成

RailsアプリのDockerイメージを作成する際、気になったポイントとしては以下です。

* REPL
* プロセス設計
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

また特定のログをS3等に保存したい場合、転送の為にfluentdやfluentbitといったエクスポーターも同様に必要になります。

AppRunnerの構造上、Rails以外のプロセスも1コンテナに同居させる必要がある為、
wrapperスクリプトを作成してその中で複数のプロセスを起動・スーパバイズし、
このスクリプトをコンテナのメインプロセスとして実行させる必要があります。

ただしこの方法は[1コンテナ1アプリパッケージ](https://cloud.google.com/architecture/best-practices-for-building-containers?hl=ja)
のベストプラクティスに反するもので、1つのコンテナで多くの事をやりすぎている為、
システムが複雑になりすぎる可能性があります。
サイドカーパターンを実現する仕組みがAppRunnerに追加されるのを待ちましょう。

なおソースコードからAppRunnerを起動させる場合は、ベースになっているランタイムの[AmazonLinuxのDockerイメージ](https://hub.docker.com/_/amazonlinux)
に対して、起動時のコマンドの中でnginxやfluentdといった必要なミドルウェアをインストールする必要があります。
頑張ればやれなくはないかもしれませんが、素直に必要なミドルウェアをインストールしたDockerイメージをECRにpushして使う方が良いでしょう。

#### Migration

Railsでアプリを運用する際、DBのマイグレーションをどう実行するかは悩みどころです。
EC2であればcapistranoで特定のサーバーをmigratorとして実行させることが可能ですし、
EKSであればJobを利用すれば1度だけマイグレーションを実行させる事が可能です。
ECSの場合はJobに相当する機構が無いので`ecs-cli`からタスクを起動してoneshotでマイグレーションを実行したり、
CodeBuildを利用してマイグレーションを実行する方法が考えられます。

AppRunnerの場合、特定のコンテナを起動する術が無いので、CodeBuildやマイグレーションの為のEC2を用意して
AppRunner外から実行させるしか方法がありません。

そもそもAppRunnerのメリットは必要なリソースを一括自動でセットアップしてくれる点なので、
マイグレーション用のリソースを別途利用するのは本末転倒な気がします。
このあたりもAWSの改善を待ちましょう。

今回作成するデモでは、Dockerの起動スクリプトにマイグレーション処理を入れて対応しました。
この方法は、タイミングによっては同時に複数のマイグレーションが走る可能性があるので、
本番環境では適用できないので注意してください。

#### Dockerfile

最終的なDockerfileは以下となりました。

```Dockerfile
# Dockerfile
FROM ruby:3.0.0

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update -qq \
    && apt-get install -y nodejs yarn \
    && mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install
COPY . /app

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# for rails & mysql process
EXPOSE 3000 3306

CMD ["entrypoint.sh"]
```

entrypoint.shは以下です。

```bash
#!/bin/bash
set -e
rm -rf tmp/*

# タイミングによっては同時に複数のマイグレーションが走る可能性があるので注意
bundle exec rake db:create
bundle exec rake db:migrate

bundle exec rails server -b 0.0.0.0
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

## 参考情報

* [新機能 – AWS App Runner: スケーラブルで安全なウェブアプリケーションをコードから数分で作成](https://aws.amazon.com/jp/blogs/news/app-runner-from-code-to-scalable-secure-web-apps/)
* [AWS App Runner のご紹介](https://aws.amazon.com/jp/blogs/news/introducing-aws-app-runner/)
* [AWS APP RUNNER WORKSHOP](https://www.apprunnerworkshop.com/)
* [AWS App Runner Documentation](https://docs.aws.amazon.com/en_us/apprunner/)
* [Terraform AWS Provider doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [AWS App Runner Roadmap](https://github.com/aws/apprunner-roadmap)
* [AWS Containers Roadmap](https://github.com/aws/containers-roadmap)
* [コンテナ構築のおすすめの方法](https://cloud.google.com/architecture/best-practices-for-building-containers?hl=ja)

