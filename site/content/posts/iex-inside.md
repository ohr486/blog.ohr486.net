---
title: "iex inside"
date: 2021-12-20T00:00:00+09:00
draft: true
tags: [ elixir, advent-calendar ]
categories: [ tech ]
author: ohr486
---

この記事は[elixir Advent Calendar 2021](https://qiita.com/advent-calendar/2021/elixir)の20日目の記事です。

elixirのプログラミングやphoenixに関する解説記事やドキュメントは比較的よく見かけるのですが、
elixir言語自体の解説/ドキュメント/資料は少ないと感じています。
そういうわけで最近はelixir本体をhackしたい人向けの言語の内部構造の解説ドキュメントを作成しています。

本記事では、そこでまとめた`iex`コマンドの起動時周辺の実装についての情報を紹介します。

## 事前準備

### erlangのインストール

[公式サイト](https://elixir-lang.org/install.html#installing-erlang) を参照してください。

### elixirのソースコードの取得

elixirのソースコードは [こちら](https://github.com/elixir-lang/elixir) からcheckoutできます。

```bash
$ git clone git@github.com:elixir-lang/elixir.git
$ cd elixir
```

### elixirのコンパイル

elixirのリポジトリで以下を実行すればコンパイルとテストが走ります。

```bash
$ make clean test
```

### コンパイルしたelixirの動作確認

`bin`の下のコマンドを実行すれば、コンパイルしたelixirを実行できます。

```bash
$ ./bin/elixir --version
Erlang/OTP 24 [erts-12.1.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Elixir 1.14.0-dev (172da44) (compiled with Erlang/OTP 24)
$
```

## iexの起動シーケンス

`iex`の実体は`erl`コマンドです。
コマンドに`ELIXIR_CLI_DRY_RUN`パラメータを付けることでコマンド実行時に何が起こっているかを見ることができます。

※ 見やすくするために改行を入れています

```bash
$ ELIXIR_CLI_DRY_RUN=1 ./bin/iex
erl
 -pa
   /Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/eex/ebin
   /Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/elixir/ebin
   /Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/ex_unit/ebin
   /Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/iex/ebin
   /Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/logger/ebin
   /Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/mix/ebin
 -elixir
   ansi_enabled true
 -noshell
 -user
   Elixir.IEx.CLI
 -extra
 --no-halt
 +iex
$
```

コマンドの実体についてはこちらの
[動画](https://youtu.be/si89UWMA77Y?t=3736) と [資料](https://speakerdeck.com/ohr486/hack-and-read-elixir?slide=10) をご参照ください。

`iex`の実体である`erl`に渡されるオプションですが、大きく3種類に分類できます。

### erlコマンドのオプション

#### エミュレーターフラグ

`+`から始まるオプションは、[エミュレータフラグ](https://www.erlang.org/doc/man/erl.html#emulator-flags) です。
このフラグはVMに渡り、VMの挙動に影響を与えます。

#### フラグ

`-`から始まるオプションは、[フラグ](https://www.erlang.org/doc/man/erl.html#flags) です。
このフラグ情報は`:init.get_arguments`で取得できます。

```bash
$ ./bin/iex
Erlang/OTP 24 [erts-12.1.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Interactive Elixir (1.14.0-dev) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> :init.get_arguments
[
  root: ['/Users/ohara_tsunenori/.asdf/installs/erlang/24.1.2'],
  progname: ['erl'],
  home: ['/Users/ohara_tsunenori'],
  pa: ['/Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/eex/ebin',
   '/Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/elixir/ebin',
   '/Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/ex_unit/ebin',
   '/Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/iex/ebin',
   '/Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/logger/ebin',
   '/Users/ohara_tsunenori/Git/github.com/ohr486/elixir/bin/../lib/mix/ebin'],
  elixir: ['ansi_enabled', 'true'],
  noshell: [],
  user: ['Elixir.IEx.CLI']
]
iex(2)>
```

`ELIXIR_CLI_DRY_RUN`を付けた際に表示された以下の引数の情報が表示されている事がわかります。

* -pa
* -elixir
* -noshell
* -user

##### -paフラグ

-paフラグは後ろに続くディレクトリのモジュールをVM起動時に読み込みます。
このフラグによって`iex`起動時に標準ライブラリ(eex,elixir,ex_unit,iex,logger,mix)がロードされます。

##### -noshellフラグ

-noshellフラグをつけるとVMがシェル無しで起動します。
このフラグはerlangとelixirのシェルが競合してしまう為、付与しているようです。

#### Plain Arguments

-extraは特別なフラグです。
-extraの後に続くフラグはPlain Argumentとして扱われ、
`:init.get_plain_arguments`で取得できるようになります。

```bash
$ ./bin/iex
Erlang/OTP 24 [erts-12.1.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Interactive Elixir (1.14.0-dev) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> :init.get_plain_arguments
['--no-halt', '+iex']
iex(2)>
```

`ELIXIR_CLI_DRY_RUN`を付けた際に表示された、-extra以降の引数の情報が表示されている事がわかります。

### -userフラグの挙動

-userフラグの挙動なんですが、ほとんど情報やドキュメントが無い様です。
少なくとも自分の観測範囲内では見つけられませんでした、
もし情報をお持ちの方いらっしゃいましたら教えてくれると嬉しいです。
最終的に [Erlangのソースコード](https://github.com/erlang/otp/blob/master/lib/kernel/src/user_sup.erl) を読んで挙動を理解する事ができました。

結論として、この-userフラグは後ろに続くモジュールの`start`関数を`erl`起動時に実行します。
`erl`コマンドは実行時にランタイムのkernelを起動するのですが、その際user_supがスーパバイザーとして起動します。
この`user_sup`モジュールはuserフラグがあった場合、後ろに続くモジュールの`start`関数を実行します。

`iex`は-userフラグの後ろに`Elixir.IEx.CLI`モジュールを指定しているので、
`erl`実行時に [Elixir.IEx.CLI](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/cli.ex) モジュールの`start`関数が実行されるわけです。

### -userフラグの動作実験

実際に-userフラグの挙動を見ていきましょう。
サンプルとして、標準出力にメッセージを出すモジュールを-userフラグの後ろに指定して動作を確認してみます。

以下のようにメッセージを出力する`start`関数を`hello`モジュールに定義します。

```erlang
-module(hello).
-export([start/0]).

start() ->
  user:start(),
  io:put_chars("hello hacking iex!").
```

事前に`hello.erl`を`erlc`でコンパイルしておきます。
コンパイルされたバイナリは拡張子`.beam`のファイルです。

```bash
$ erlc hello.erl
$ ls
hello.beam hello.erl
```

-userフラグの後ろにコンパイルした`hello`モジュールを指定して`erl`を起動した結果が以下です。
合わせて`init:get_arguments`でフラグ情報も表示しています。

```bash
$ erl -user hello
hello hacking iex!Eshell V12.1.2  (abort with ^G)
1> init:get_arguments().
[{root,["/Users/ohara_tsunenori/.asdf/installs/erlang/24.1.2"]},
 {progname,["erl"]},
 {home,["/Users/ohara_tsunenori"]},
 {user,["hello"]}]
2>
```

起動時に、`hello`モジュールの`start`関数が実行され`hello hacking iex!`の文字列が出力されているのがわかります。
確かに-userフラグで指定しているモジュールの`start`関数が実行されているようです。

### userモジュールとは何か

`hello`モジュールの`start`関数の中で`user:start()`が実行されているのが気になった人がいるかもしれません。
`io:put_chars`などの標準出力処理は [userモジュール](https://www.erlang.org/doc/man/user.html) が起動していないと実行されません。

`user`モジュールは標準入出力に流れるメッセージに応答するI/Oサーバーを提供します。
`io:put_chars`はこのI/Oサーバーに対してメッセージを書き込むので、
事前にuserモジュールを起動する必要があったのです。

### elixirのレベルでのエントリポイント

ようやく`iex`コマンドから
[Elixir.IEx.CLI](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/cli.ex)
モジュールの`start`関数にたどり着きました。
この`start`関数がelixirレベルでの`iex`コマンドのエントリポイントになります。

## IEx.CLI.start 実行時の関数呼び出し構造

`IEx.CLI.start`実行時にcallされるapiの全体概要は以下となります。

![iexのプロセス構造](/images/2021-12-20/iex-api-flow.png)

iexのREPLが実行される処理は大きく以下のフェーズに分類できます。

* スーパバイザの起動
* elixirモジュールの起動
* IEx.Server.shell_loop
* IEx.Server.loop
* IEx.Evaluator.loop
* IEx.Evaluator.eval

### スーパバイザの起動

![iexスーパバイザ](/images/2021-12-20/iex-sup.png)

`IEx.CLI.start` がcallされると、内部的に`:user.start()`がcallされI/Oサーバーであるuserモジュールが起動します。
また、`IEx.Supervisor`が起動し`IEx.Config`、`IEx.Broker`、`IEx.Pry`サーバーが起動します。

`iex`の実行に必要なプロセスを起動した後に、`IEx.Server.run_from_shell`でREPLの実体となる処理をcallします。

### elixirモジュールの起動

![elixirモジュール起動](/images/2021-12-20/iex-elixir-up.png)






### IEx.Server.shell_loop

![shell-loop](/images/2021-12-20/iex-server-shell-loop.png)

### IEx.Server.loop

![server-loop](/images/2021-12-20/iex-server-loop.png)

### IEx.Evaluator.loop

![evaluator-loop](/images/2021-12-20/iex-evaluator-loop.png)

### IEx.Evaluator.eval

![evaluator-eval](/images/2021-12-20/iex-evaluator-eval.png)


## elixirコードのeval




## iex改造




## まとめ
