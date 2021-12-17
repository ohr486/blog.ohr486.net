---
title: "iex inside"
date: 2021-12-20T00:00:00+09:00
draft: false
tags: [ elixir, advent-calendar ]
categories: [ tech ]
author: ohr486
---

この記事は[elixir Advent Calendar 2021](https://qiita.com/advent-calendar/2021/elixir)の20日目の記事です。

elixirのプログラミングやphoenixに関する解説記事やドキュメントは比較的よく見かけるのですが、
elixir言語自体の解説/ドキュメント/資料は少ないと感じています。
そういうわけで最近はelixir本体をhackしたい人向けの言語の内部構造の解説ドキュメントを作成しています。

本記事では、そこでまとめた`iex`コマンドの起動時周辺の実装についての情報を紹介します。

(注意) この記事はelixirの1.14のバージョンを元に作成しています、
elixirのバージョンupに伴って内容が変わる可能性があります

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
  io:put_chars("hello hacking iex!\n").
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
hello hacking iex!
Eshell V12.1.2  (abort with ^G)

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

![iex-api-flow](/images/2021-12-20/iex-api-flow.png)

iexのREPLが実行される処理は大きく以下のフェーズに分類できます。

* スーパバイザの起動
* elixirモジュールの起動
* IEx.Server.shell_loop
* IEx.Server.loop
* IEx.Evaluator.loop
* IEx.Evaluator.eval

### スーパバイザの起動

![iex-sup](/images/2021-12-20/iex-sup.png)

`IEx.CLI.start` がcallされると、内部的に`:user.start()`がcallされI/Oサーバーであるuserモジュールが起動します。

[lib/iex/lib/iex/cli.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/cli.ex)

```elixir
defmodule IEx.CLI do
  # 〜 snip 〜

  def start do
    if tty_works?() do
      # 〜 snip 〜
    else
      # 〜 snip 〜

      :user.start()

      IEx.start([register: true] ++ options(), {:elixir, :start_cli, []})
    end
  end

  # 〜 snip 〜
end
```

また`IEx.start`から最終的に`IEx.Supervisor`が起動し`IEx.Config`、`IEx.Broker`、`IEx.Pry`サーバーが起動します。

[lib/iex/lib/iex/app.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/app.ex)

```elixir
defmodule IEx.App do
  # 〜 snip 〜

  def start(_type, _args) do
    children = [IEx.Config, IEx.Broker, IEx.Pry]
    Supervisor.start_link(children, strategy: :one_for_one, name: IEx.Supervisor)
  end
end
```

`iex`の実行に必要なプロセスを起動した後に、`IEx.Server.run_from_shell`で`iex`のREPLの実体となる処理をcallします。

### elixirモジュールの起動

![iex-elixir-up](/images/2021-12-20/iex-elixir-up.png)

`IEx.Server.run_from_shell`は`spawn_monitor`で`:elixir.start_cli()`を実行するプロセスをspawnし、
`Iex.Server.shell_loop`でメッセージを待ち受けます。

[lib/iex/lib/iex/server.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/server.ex)

```elixir
defmodule IEx.Server do
  # 〜 snip 〜

  # {m,f,a}={:elixir,:start_cli,[]}としてcallされる
  def run_from_shell(opts, {m, f, a}) do
    # 〜 snip 〜

    # :elixir.start_cli() を実行するプロセスを監視付きで生成
    {pid, ref} = spawn_monitor(m, f, a)

    # spawn_monitor 後、メッセージを待ち受ける
    shell_loop(opts, pid, ref)
  end
  
  # 〜 snip 〜
end
```


#### spawn_monitor

`:elixir.start_cli()`は [spawn_monitor](https://hexdocs.pm/elixir/1.13.1/Kernel.html#spawn_monitor/3) で生成されたプロセスで実行されます。
`spawn_monitor(Mod,Fun,Args)`はプロセスを監視付きで生成し、
生成先のプロセスで引数として渡した関数(Mod,Fun,Args)の実行が完了した際に、
プロセスの終了メッセージを明示的に受け取る事ができます。

プロセスの終了時にうけとるメッセージは以下です。

```elixir
# 正常にプロセスが終了した場合
{:DOWN, ref, :process, pid, :normal}

# エラーでプロセスが終了した場合、reasonにはエラー情報が入ります
{:DOWN, ref, :process, pid, reason}
```

#### spawn_monitorの動作実験

`iex`で`spawn_monitor`の動作実験をしてみましょう。
10秒sleepしてメッセージを出力する関数`spawn_monitor`を実行するプロセスを生成してみます。

```elixir
defmodule Foo do
  def bar do
    IO.puts "Foo#bar start"
    :timer.sleep(10000)
    IO.puts "sleep end"
    :ok
  end
end
```

`iex`上でこのモジュール`Foo`を定義し、`Foo.bar()`を実行するプロセスを生成した結果が以下です。
`flush`は受け取ったメッセージを表示する`iex`のコマンドです。

```bash
$ ./bin/iex
Erlang/OTP 24 [erts-12.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Interactive Elixir (1.14.0-dev) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> defmodule Foo do
...(1)>   def bar do
...(1)>     IO.puts "Foo#bar start"
...(1)>     :timer.sleep(10000)
...(1)>     IO.puts "sleep end"
...(1)>     :ok
...(1)>   end
...(1)> end
{:module, Foo,
 <<70, 79, 82, 49, 0, 0, 5, 140, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0, 0, 163,
   0, 0, 0, 19, 10, 69, 108, 105, 120, 105, 114, 46, 70, 111, 111, 8, 95, 95,
   105, 110, 102, 111, 95, 95, 10, 97, 116, ...>>, {:bar, 0}}

iex(2)> spawn_monitor(Foo, :bar, [])
Foo#bar start
{#PID<0.118.0>, #Reference<0.4069173944.326107139.44304>}

iex(3)> flush
:ok

〜 10秒後 〜

sleep end

iex(4)> flush
{:DOWN, #Reference<0.4069173944.326107139.44304>, :process, #PID<0.118.0>,
 :normal}
:ok

iex(5)>
```

`spawn_monitor`でプロセスを生成後、そのプロセス内で`Foo.bar()`が実行されます。
10秒のsleepの後メッセージを表示してプロセスは終了します。

上の実行結果では、`sleep end`のメッセージが出力された後に`flush`を実行して、
`{:DOWN, #Reference<0.4069173944.326107139.44304>, :process, #PID<0.118.0>, :normal}`
のメッセージを受け取っています。
メッセージは`{:DOWN, ref, :process, pid, :normal}`の形式なので、
正常に`Foo.bar()`が実行されて終了したプロセスだとわかります。

#### shell_loop

`IEx.Server.shell_loop`は`:elixir.start_cli()`終了後に送信される
`{:DOWN, ref, :process, pid, :normal}`のメッセージを受け取り、
`IEx.Server.run_without_registration`をcallします。

[lib/iex/lib/iex/server.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/server.ex)

```elixir
defmodule IEx.Server do
  # 〜 snip 〜

  defp shell_loop(opts, pid, ref) do
    receive do
      # 〜 snip 〜

      # :elixir.start_cli()の完了後のプロセス終了メッセージ
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        run_without_registration(opts)

      # 〜 snip 〜
    end
  end
  
  # 〜 snip 〜
end
```

### IEx.Evaluator.loop

![iex-evaluator-loop](/images/2021-12-20/iex-evaluator-loop.png)

`IEx.Server.shell_loop`の中で`IEx.Server.run_without_registration`がcallされると、
最終的に`IEx.Evaluator.loop`のプロセスが立ち上がりメッセージを待ち受けます。
この`IEx.Evaluator.loop`は`{:eval, pid, code, state}`の
メッセージを受け取ってcode(elixirのソースコードの文字列)をevalします。
このevalの結果を`{:evaled, pid, status, result}`として送信元に返却した後、
loopを再び呼び出してメッセージを待ち受けなおします。

[lib/iex/lib/evaluator.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/evaluator.ex)

```elixir
defmodule IEx.Evaluator do
  # 〜 snip 〜

  defp loop(%{server: server, ref: ref} = state) do
    receive do
      # codeはelixirのコードの文字列
      {:eval, ^server, code, iex_state} ->
      
        # codeをevalする
        {result, status, state} = eval(code, iex_state, state)
        
        # evalの結果を送信元のプロセスに{:evaled, ...}として返却
        send(server, {:evaled, self(), status, result})
        
        # evalが終わったら再びloopでメッセージを待ち受ける
        loop(state)

      # 〜 snip 〜
    end
  end

  # 〜 snip 〜
end
```

### IEx.Server.loop

![iex-server-loop](/images/2021-12-20/iex-server-loop.png)

`IEx.Server.run_without_registration`は前節の通り
`IEx.Evaluator.loop`のプロセスを立ち上げた後、
`IEx.Server.loop`のプロセスを立ち上げます。

`iex`のREPLの実体はこの`IEx.Server.loop`です。

#### Read

![iex-server-loop-read](/images/2021-12-20/iex-server-loop-read.png)

`IEx.Server.loop`は`spawn`で`IEx.Server.io_get`を実行してユーザーからの入力を受け取るプロセスを生成します。
そして`IEx.Server.wait_input`でその入力結果のメッセージを待ち受けます。

[lib/iex/lib/server.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/server.ex)

```elixir
defmodule IEx.Server do
  # 〜 snip 〜

  defp loop(state, prompt, evaluator, evaluator_ref) do
    # 〜snip〜

    # ユーザーからの入力を受け取るプロセスを生成
    input = spawn(fn -> io_get(self_pid, prompt_type, prefix, counter) end)

    # 入力が終了するまで待ち受ける
    wait_input(state, evaluator, evaluator_ref, input)
  end
  
  # 〜 snip 〜
end
```

`IEx.Server.io_get`は標準入力から入力を受け取り
`{:input, pid, <入力内容>}`
のメッセージを呼び出し元のプロセスに返却します。

[lib/iex/lib/server.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/server.ex)

```elixir
defmodule IEx.Server do
  # 〜 snip 〜

  defp io_get(pid, prompt_type, prefix, counter) do
    # 〜 snip 〜

    # 標準入力内容をメッセージとして返却
    send(pid, {:input, self(), IO.gets(:stdio, prompt)})
  end

  # 〜 snip 〜
end
```

このメッセージは`IEx.Server.wait_input`で受け取ります。

[lib/iex/lib/server.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/server.ex)

```elixir
defmodule IEx.Server do
  # 〜 snip 〜

  defp wait_input(state, evaluator, evaluator_ref, input) do
    receive do
      # 入力終了時の受信メッセージ
      {:input, ^input, code} when is_binary(code) ->

        # 入力内容(code)をevaluatorに送信
        # evaluatorは前節の IEx.Evaluator.loop のプロセスID
        send(evaluator, {:eval, self(), code, state})
      
        # evalが終了するまで待ち受ける
        wait_eval(state, evaluator, evaluator_ref)

      # 〜 snip 〜
    end
  end
  
  # 〜 snip 〜
end
```

#### Eval & Print

![iex-server-loop-eval](/images/2021-12-20/iex-server-loop-eval.png)

`IEx.Server.wait_input`で入力内容を受け取ったら、
`IEx.Evaluator.loop`のプロセスに対して
`{:eval, pid, code, state}`のメッセージを送信します。
そして、evalが終了するまで`IEx.wait_eval`でeval結果のメッセージを待ち受けます。

[lib/iex/lib/server.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/server.ex)

```elixir
defmodule IEx.Server do
  # 〜 snip 〜

  defp wait_eval(state, evaluator, evaluator_ref) do
    receive do
      # IEx.Evaluator.loopから返却されるeval結果
      {:evaled, ^evaluator, status, new_state} ->
      
        # eval結果を受け取ったら再びloopでREPLの入力を待ち受ける
        loop(new_state, status, evaluator, evaluator_ref)

      # 〜 snip 〜
    end
  end

  # 〜 snip 〜
end
```

#### Loop

![iex-server-loop-print](/images/2021-12-20/iex-server-loop-print.png)

evalの結果を受け取ったら、再び`IEx.Server.loop`をcallしてREPLの入力を待ち受けます。

以上が`iex`のREPLのループ構造です。
このループによって、`iex`でelixirのコードが評価されていきます。

## elixirコードのeval

![iex-evaluator-loop-eval](/images/2021-12-20/iex-evaluator-loop-eval.png)

前節で説明した通り、
`IEx.Evaluator.loop`のプロセスにelixirのソースコードを含む`{:eval, ..., code, ...}`のメッセージを送信すれば
`{:evaled, ..., result}`としてevalの結果が返却されます。
`IEx.Evaluator.loop`の内部的では`IEx.Evaluator.eval`がcallされます。

`iex`のREPLで入力されたelixirのコード(の文字列)が評価(eval)されて結果が返却されるまでに、
どういう処理がはしっているのでしょうか。

#### String, Charlist, Tokens, Forms, Result

elixirコードの文字列が評価される時、以下のようにデータが変換されます。

![code-token-form-eval](/images/2021-12-20/code-token-form-eval.png)

CharlistからTokens、TokensからForms(Quoted)の変換とForms(Quoted)の評価は
`elixir`モジュールの関数を呼び出して処理されます。

例として`iex`で`1 + 1`のelixirコードを順番に処理し、最終的に`2`という結果を取得してみましょう。

##### String.to_charlist

```elixir
iex(1)> String.to_charlist("1 + 1")
'1 + 1' # charlist
iex(2)>
```

`String.to_charlist`は文字列をcharlistに変換します。

##### :elixir.string_to_tokens

```elixir
iex(2)> :elixir.string_to_tokens(
iex(2)>   '1 + 1',  # charlistに変換したコード
iex(2)>   1,        # ソースファイル内でのコードの開始行
iex(2)>   1,        # ソースファイル内でのコードの開始位置
iex(2)>   "nofile", # ソースファイル名
iex(2)>   []        # option
iex(2)> )
{:ok,
  [
    {:int, {1, 1, 1}, '1'},
    {:dual_op, {1, 3, nil}, :+},
    {:int, {1, 5, 1}, '1'}
  ]
}
iex(3)>
```

`:elixir.string_to_tokens(charlist, line, colum, file, opt)`は、charlistをトークンに変換します。
この関数は以下の引数をとります。

* charlist: elixirコードのcharlist
* line: ソースファイル内でのコードの開始行
* colum: ソースファイル内でのコードの開始位置
* file: ソースファイル名
* opt: オプション情報

##### :elixir.tokens_to_quoted

```elixir
iex(3)> :elixir.tokens_to_quoted(
iex(3)>   # tokens
iex(3)>   [
iex(3)>     {:int, {1, 1, 1}, '1'},
iex(3)>     {:dual_op, {1, 3, nil}, :+},
iex(3)>     {:int, {1, 5, 1}, '1'}
iex(3)>   ],
iex(3)>   "nofile", # ソースファイル名
iex(3)>   [], # option
iex(3)> )
{:ok,
  {:+, [line: 1], [1, 1]}
}
iex(4)>
```

`:elixir.tokens_to_quoted(tokens, file, opt)`は、トークンをフォームデータに変換します。
この関数は以下の引数をとります。

* tokens: トークン
* file: ソースファイル名
* opt: オプション情報

##### :elixir.eval_forms

```elixir
iex(4)> :elixir.eval_forms(
iex(4)>   {:+, [line: 1], [1, 1]}, # forms
iex(4)>   [],                      # bindings
iex(4)>   []                       # env
iex(4)> )
{
  2,              # eval結果
  [],             # bindings
  #Macro.Env<...> # env
}
iex(5)>
```

`:elixir.eval_forms(forms, bindings, env)`は、フォームデータを評価して結果を返却します。
この関数は以下の引数をとります。

* forms: フォームデータ
* bindings: 変数の束縛情報
* env: 環境情報

`1 + 1`のelixirコードの文字列から、最終的に評価結果の`2`が取得できました。
`IEx.Evaluator.eval`はこの様にしてREPLで入力されたelixirコードの文字列を評価し、
結果を取得しているのです。

#### IEx.Evaluator.evalの実体

`IEx.Evaluator.eval`がelixirコードを評価する流れは以下となります。

![iex-evaluator-eval](/images/2021-12-20/iex-evaluator-eval.png)

`IEx.Evaluator.parse`では、
`:elixir.string_to_tokens`をcallしてelixirコードをトークンに変換(tokenize)、
`:elixir.tokens_to_quoted`をcallしてトークンをフォームデータに変換(parse)します。

[lib/iex/lib/evaluator.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/evaluator.ex)

```elixir
defmodule IEx.Evaluator do
  # 〜 snip 〜

  def parse(input, opts, {buffer, last_op}) do
    # 〜 snip 〜
    
    # stringをcharlistに変換
    charlist = String.to_charlist(input)

    result =
      with # charlistをtokenに変換(tokenize)
           {:ok, tokens} <- :elixir.string_to_tokens(charlist, line, column, file, opts),
           {:ok, adjusted_tokens} <- adjust_operator(tokens, line, column, file, opts, last_op),
           # tokensをformsに変換(parse)
           {:ok, forms} <- :elixir.tokens_to_quoted(adjusted_tokens, file, opts) do
        last_op =
          # 〜 snip 〜

        {:ok, forms, last_op}
      end

    case result do
      # tokenize, parseが成功したら結果をformsとして返却
      {:ok, forms, last_op} ->
        {:ok, forms, {"", last_op}}

      # 〜 snip 〜
    end
  end

  # 〜 snip 〜
end
```

また`IEx.Evaluator.handle_eval`でこのフォームデータを`:elixir.eval_forms`をcallして評価(eval)し、結果を取得します。

[lib/iex/lib/evaluator.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/evaluator.ex)

```elixir
defmodule IEx.Evaluator do
  # 〜 snip 〜

  defp handle_eval(forms, line, state) do
    # 〜 snip 〜

    {result, binding, env} = :elixir.eval_forms(forms, state.binding, state.env)

    # 〜 snip 〜
  end

  # 〜 snip 〜
end
```

以上がelixirコードのevalの概要です。

## iexの改造

REPLで入力された文字列がparse、evalされる様子をより視覚的に理解する為に、
parse結果のフォームデータ、eval結果のbinding(変数の束縛)をそれぞれ出力するように
`iex`を改造してみましょう。

### parse結果の表示

REPLの入力文字列をフォームデータに変換する処理は、`IEx.Evaluator.parse`関数でした。
この`parse`関数を以下のコードを追加して、フォームデータを出力するように変更します。

[lib/iex/lib/evaluator.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/evaluator.ex)

追加するコード

```elixir
# ----- Add for iex Hack! -----
IO.puts "===== forms ====="
IO.inspect elem(result, 1) # resultの2番目の要素はforms
# -----------------------------
```

追加後の`parse`関数

```elixir
defmodule IEx.Evaluator do
  # 〜 snip 〜

  def parse(input, opts, {buffer, last_op}) do
    input = buffer <> input
    file = Keyword.get(opts, :file, "nofile")
    line = Keyword.get(opts, :line, 1)
    column = Keyword.get(opts, :column, 1)
    charlist = String.to_charlist(input)

    result =
      with {:ok, tokens} <- :elixir.string_to_tokens(charlist, line, column, file, opts),
           {:ok, adjusted_tokens} <- adjust_operator(tokens, line, column, file, opts, last_op),
           {:ok, forms} <- :elixir.tokens_to_quoted(adjusted_tokens, file, opts) do
        last_op =
          case forms do
            {:=, _, [_, _]} -> :match
            _ -> :other
          end

        {:ok, forms, last_op}
      end

    # ----- Add for iex Hack! -----
    IO.puts "===== forms ====="
    IO.inspect elem(result, 1) # resultの2番目の要素はforms
    # -----------------------------

    case result do
      {:ok, forms, last_op} ->
        {:ok, forms, {"", last_op}}

      {:error, {_, _, ""}} ->
        {:incomplete, {input, last_op}}

      {:error, {location, error, token}} ->
        :elixir_errors.parse_error(
          location,
          file,
          error,
          token,
          {charlist, line, column}
        )
    end
  end
  
  # 〜 snip 〜
end
```

### eval結果の表示

`parse`関数と同様に、フォームデータのevalを行う`handle_eval`関数に以下のコードを追加して、
eval結果のbindings(変数の束縛情報)を表示するようにします。

[lib/iex/lib/evaluator.ex](https://github.com/elixir-lang/elixir/blob/main/lib/iex/lib/iex/evaluator.ex)

追加するコード

```elixir
# ----- iex hack! -----
IO.puts "===== binding ==="
IO.inspect binding
IO.puts "================="
# ---------------------
```

追加後の`handle_eval`関数

```elixir
defmodule IEx.Evaluator do
  # 〜 snip 〜

  defp handle_eval(forms, line, state) do
    forms = add_if_undefined_apply_to_vars(forms)
    {result, binding, env} = :elixir.eval_forms(forms, state.binding, state.env)

    # ----- iex hack! -----
    IO.puts "===== binding ==="
    IO.inspect binding
    IO.puts "================="
    # ---------------------

    unless result == IEx.dont_display_result() do
      io_inspect(result)
    end

    state = %{state | env: env, binding: binding}
    update_history(state, line, result)
  end

  # 〜 snip 〜
end
```

### 改造iexの動作実験

`evaluator.ex`を変更したら、`make`コマンドでelixirをリビルドします。

```bash
$ make
==> iex (compile)
Generated iex app
$
```

変更があった`iex`モジュールがコンパイルされています。
コンパイルが終わったら`./bin/iex`で改造した`iex`を起動し、elixirコードを実行してみます。

```bash
$ ./bin/iex
Erlang/OTP 24 [erts-12.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Interactive Elixir (1.14.0-dev) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> 1 + 1
===== forms =====
{:+, [line: 1], [1, 1]}
===== binding ===
[]
=================
2

iex(2)> a = 123
===== forms =====
{:=, [line: 2], [{:a, [line: 2], nil}, 123]}
===== binding ===
[a: 123]
=================
123

iex(3)> b = [1, 2, 3]
===== forms =====
{:=, [line: 3], [{:b, [line: 3], nil}, [1, 2, 3]]}
===== binding ===
[b: [1, 2, 3], a: 123]
=================
[1, 2, 3]

iex(4)> IO.puts "hello, hacked iex!"
===== forms =====
{{:., [line: 4], [{:__aliases__, [line: 4], [:IO]}, :puts]}, [line: 4],
 ["hello, hacked iex!"]}
hello, hacked iex!
===== binding ===
[b: [1, 2, 3], a: 123]
=================
:ok

iex(5)> defmodule Hoo do; end
===== forms =====
{:defmodule, [line: 5],
 [{:__aliases__, [line: 5], [:Hoo]}, [do: {:__block__, [], []}]]}
===== binding ===
[b: [1, 2, 3], a: 123]
=================
{:module, Hoo,
 <<70, 79, 82, 49, 0, 0, 3, 232, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0, 0, 129,
   0, 0, 0, 13, 10, 69, 108, 105, 120, 105, 114, 46, 72, 111, 111, 8, 95, 95,
   105, 110, 102, 111, 95, 95, 10, 97, 116, ...>>, nil}

iex(6)>
```

REPLの表示結果に、elixirコードのフォームデータとbinding情報が表示されるようになりました。
いろんなelixirコードを入力して試してみてください。

## まとめ

`iex`はerlang/elixirで実装されている為、他言語で実装されたインタプリタに比べて構造が「立体的」になります。
C言語などの逐次処理をベースとした設計に比べて、複数(たくさん)のプロセスやメッセージが登場し、
処理を追ったり理解するのが比較的難しいかもしれません。
一方、Erlang/Elixirのアクターモデルによる設計/実装の面白さもあります。

`iex`をはじめとした、elixirのコアモジュールは読み応えがあり、記事の中で紹介した通り簡単に改造する事ができます。
これを機会にelixirをhackしてみてはいかがでしょうか？
