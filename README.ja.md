<style>
.method {
  color: orangered;
  font-family: Courier;
}
.header {
  color: green;
}
.param_header {
  margin: 0em;
  font-weight: bold;
  color: dimgray;
}
.param {
  color: blue;
}
.type {
  color: dimgray;
  font-style: italic;
}
body {
  font-family: times;
  padding-left: 1em; 
  background-color: ghostwhite;
}
.ex {
  background-color: black;
  color: white;
  padding: 1em;
  font-family: Courier;
  margin-left: 4em;
  width: 70em;
  font-size: 0.9em;
  white-space: pre;
}
.eh {
  color: lightblue;
}
.em {
  color: orange;
}
.terminal {
  background-color: white;
  border: dashed 1px black;
  padding: 1em;
  font-family: Courier;
  margin-left: 4em;
  width: 40em;
}
</style>

<h1 style="color: orangered;">SimpleRotate</h1>
SimpleRotate はログを記録する為の非常にシンプルで理解しやすい gemライブラリです。  
ログをローテーションする機能もついています。  

Version: 1.0.0  
対応Ruby Versions: 1.9.3, 2.0.0, 2.1.0 (for Linux)  
License: MIT  
登録gemリポジトリ: http://rubygems.org (<a href="http://rubygems.org/gems/simple_rotate">http://rubygems.org/gems/simple_rotate</a>)  

<h2 class="header">Installation</h2>
gemコマンドを使ってインストールできます。
<p class="terminal">
$ gem install simple\_rotate
</p>

外部ライブラリなので reqireで読み込みます。
<p class="terminal">
require 'simple_rotate'
</p>


<h2 class="header" id="multi">Tips</h2>
### マルチスレッド、マルチプロセスについて  
* マルチスレッド  
SimpleRotate はスレッドセーフになるように設計されています。  
ファイルを開く、新規作成する、ローテーションする、ログを書き込むなどの処理は Mutexで排他制御されています。  
書き込みの際に inode番号を調べ常に新しいファイルに書き込みできるように同期を試みます。  
このモードはデフォルトで有効です。  
\#no\_sync\_inodeを呼び出せば inode番号の同期の確認をスキップできますが 複数プロセスや複数スレッドの場合は推奨しません。  

* マルチプロセス  
\#psafe\_mode を呼び出すとプロセスセーフモードになります。  
このモードを有効にするとログの書き込み、ファイルのローテーションなどの処理がプロセス間で排他ロックされるようになります。  
書き込みの際に inode番号を調べ常に新しいファイルに書き込みできるように同期を試みます。  
また、書き込みの後 I/Oポートの内部バッファをフラッシュします。  
この機能は SimpleRotateの内部クラスである ProcessSyncクラスによって実装されています。  
通常起こり得ませんが プロセス間排他ロック取得時に予期しないエラーが起きると 3回まで再びロック取得を試みます。  
3度目が失敗するとロックを取得しないで処理を行います 。   
プロセスセーフモードが有効の状態で ProcessSyncオブジェクトを生成すると排他ロック用の一時ファイルが生成されます。  
一時ファイルは .SimpleRotate\_tempfile\_【プログラムのファイル名】という命名規則でログファイルと同じディレクトリに生成され、  
Rubyの終了処理で削除されるようにスケジューリングされます。  
一時ファイル生成の際に既に同じ名前のファイルが存在する場合や  
終了処理で一時ファイルが空でない場合や削除するパーミッションがない場合は一時ファイルの削除は実行されません。  


<h2 class="header">Usage</h2>

### Public Class Methods
* <span class="method">instance</span>  
SimpleRotateオブジェクトを返します。  
SimpleRotate Class は Singletonパターンで実装されています。  
従って返却するオブジェクトは唯一の SimpleRotateオブジェクトです。  
initilizeメソッドが privateになりオブジェクトからのアクセスはできない為 newメソッドを使うとエラーなります。  

### Public Instance Methods
* <span class="method">init([file\_name, [limit, [generation]]])</span>   
ログの取り方に関する設定をします。  
ここで設定した内容は、後に SimpleRotate::instance で返されるオブジェクトも保持し続けます。  
返り値は self です。  
<div class="param_header">Parameters</div>
  * <span class="type">String|Symbol</span> <span class="param">file\_name="./実行ファイル名.log"</span>  
ログを出力するファイル名を指定します。  
フルパス、もしくは相対パスで指定します。  
相対パスの場合は、実行ファイルが起点になります。  
ここで指定したファイルと同じファイルが存在する場合、そのファイルに追加書き込みします。  
ファイルではなく標準出力のみに出力したい場合はシンボルで、:STDOUT と指定します。   
デフォルトは "./実行ファイル名.log" です。  
<br />
  * <span class="type">Integer|String</span> <span class="param">limit="1M"</span>  
ログファイルの最大サイズを指定します。  
initメソッド、wメソッドでログファイルのサイズを評価し ここで指定した設定値を超えていた場合、次のファイルに書き込みます。    
その際、古いファイルは下記のようにリネームされます。  
file\_name.1、file\_name.2、file\_name.3、file\_name.4 という具合に、古いログファイルほど古い数字が記されます。  
数字、もしくは "1G" 等の文字列で指定します。"K", "M", "G" が認識されます。  
デフォルトは "1M" ですので 1Mの容量を超えると次のファイルに書き込みされます。  
<br />
上記のようにファイルの容量でなく一定の期日ごとにローテーションする事も可能です。    
"DAILY", "WEEKLY", "MONTHLY" を指定します。   
その場合は、それぞれログファイルの作成日を起点に1日毎、7日毎、30日毎ごとに次のファイルに書き込みされます。  
ローテーションのタイミングで古いファイル名は file\_name.YYYYmmdd にリネームされます。  
<br />
   * <span class="type">Integer</span> <span class="param">generation=0</span>  
古いログファイルの最大数を指定します。  
古いログファイルはここで指定した数で世代交代します。  
例えば generation に 4 を設定すると、古いログファイルは  
file\_name.1、file\_name.2、file\_name.3、file\_name.4 の4世代まで作られます。  
この場合、新しいログファイルを入れると最大5つのファイルでローテーションします。  
値を 0 に設定すると世代交代は行わません。  
長期間放置しておくとディスク領域を圧迫する可能性がありますので手ごろな回数で世代交代することをおすすめします。  
デフォルトは 0ですので世代交代は行われません。   

ブロック付きでコールする事もできます。  
ブロックを抜けると自動でログファイルのI/Oポートを閉じます。   
<p class="ex"><span class="eh">example:</span>
logger = SimpleRotate.instance
logger.init("foo.log") do |sr|
  sr << "log message"
end
logger.init("bar.log") do |sr|
  sr << "log message"
end
</p>


* <span class="method">with\_stdout</span>  
ログメッセージを標準出力(STDOUT)にも出すようにします。  

* <span class="method">compress</span>  
ローテーションする際に古いログファイルを gzip圧縮します。  
zlib を読み込みます。  
デフォルトは圧縮は行いません。  
\#init でローテーションが行われる可能性がある為 #init の前に行うべきです。  

* <span class="method">compress\_level(level)</span>  
圧縮レベルを指定します。  
数字が高い方が圧縮度が高くなります。   
デフォルトの圧縮レベルは、Zlib::DEFAULT\_COMPRESSION です。  
このメソッドを呼び出すと圧縮が有効に切り替わります。  
level を返します。  
\#init でローテーションが行われる可能性がある為 #init の前に行うべきです。  
<div class="param_header">Parameters</div>  
  * <span class="type">Integer</span> <span class="param">lelvel</span>  
圧縮レベルを 0-9 の数字で指定します。  

* <span class="method">w(message)</span>  
ログメッセージをファイルに書き込みます。  
ログメッセージは、ログレベルの情報を持ちます。  
直近に実行したログレベルを決めるメソッド(#debug, #info, #warn, #error, #fatal) でログレベルは決まります。  
ログレベルを決めるメソッドが一度も実行されてないオブジェクトは "INFO" をログレベルに持ちます。  
<div class="param_header">Parameters</div>  
  * <span class="type">mixed</span> <span class="param">message</span>  
ファイルに出力するログメッセージを指定します。  
Stringでなくても Integerや Floatでも構いません。   
Arrayを指定する事も可能です。   

<p class="ex"><span class="eh">example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log")
ary = [111, 333, 555]
logger.w ary
logger.error.w("エラーです")

  <span class="em">下記のようにログファイルに出力されます。</span>
<span style="color: yellow;">[2014/01/15 19:44:22] - INFO : [111, 333, 555]   
[2014/01/15 19:44:22] - ERROR : エラーです</span>
</p>


* <span class="method">&lt;&lt; message</span>  
\#w のエイリアスです。  


* <span class="method">enable\_wflush</span>  
\#w を呼び出した後 I/Oポートの内部バッファをフラッシュします。  


* <span class="method">disable\_wflush</span>  
\#w を呼び出した後 I/Oポートの内部バッファをフラッシュしません。  
デフォルトはこの挙動です。  


* <span class="method">e</span>  
ログファイルの I/Oポートを閉じます。  
\#init のパラメータ file\_name  に :STDOUT を指定した場合は nilを返します。    


* <span class="method">reopen</span>  
閉じたログファイルの I/Oポートを開きます。  
返り値は Fileオブジェクトです。  
\#init のパラメータ file\_name  に :STDOUT を指定した場合は nilを返します。      
また、I/Oポートを閉じていない時に呼び出すとエラーメッセージを出し nilを返します。

* <span class="method">flush</span>  
強制ローテーションを実行します。  
ファイルサイズが limit に満たないファイルをローテーションしたい時に使います。  
ただし、limit に "DAILY" や "WEEKLY" などのファイルサイズ以外のものを指定した場合はローテーションせず nilを返します。   
\#init のパラメータ file\_name  に :STDOUT を指定した場合は nilを返します。    


* <span class="method">threshold [= log\_level]</span>  
全てのログは "DEBUG" < "INFO" < "WORN" < "ERROR" < "FATAL" までのログレベルを持ちます。  
左から右にかけてログの深刻度は増していきます。  
ここで指定するのはどのレベル以降のログをファイルに出力するかです。  
例えば、"ERROR" を閾値に指定すると "ERROR", "FATAL" 以外のレベルのログはファイルに出力されません。  
デフォルトは "INFO" です。  
値を定義しない場合は現在値を返却します。  
<div class="param_header">Parameters</div>  
  * <span class="type">String</span> <span class="param">log\_lelvel</span>  
"DEBUG", "INFO", "WORN", "ERROR", "FATAL" のいずれかの文字列です。  
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log", "DAILY")
logger.threshold = "ERROR"
</p>


* <span class="method">logging\_format [= format]</span>  
<div class="param_header">Parameters</div>  
  * <span class="type">String</span> <span class="param">format</span>  
ファイルにログを出力する際のフォーマットを指定します。  
フォーマットで使用できる定数は以下です。
<span style ="color: green; font-size: smaller;">  
$DATE  - 日付です。日付のフォーマットは #date\_format で定義できます。  
$PID   - プログラムのプロセスIDです。  
$LEVEL - ログのレベルです。  
$LOG   - ログ本体、#w(message) の引数です。  
$FILE  - 現在実行中の Ruby スクリプトのファイル名(ファイル名のみ)です。  
$FILE-FUL  - 現在実行中の Ruby スクリプトのファイル名(絶対パス)です。  
</span>  
デフォルトは "[$DATE] - $LEVEL : $LOG" ですので、  
[2013/10/04 17:42:06] - FATAL : foo  
のように出力されます。  
値を定義しない場合は現在値を返却します。  
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log", "1G")
logger.logging\_format = "[$LEVEL] : $DATE => $LEVEL: [$LOG] @ $FILE-FUL"
logger.fatal.w("test")
  <span class="em">下記のようにログファイルに出力されます。</span>
<span style="color: yellow;">[FATAL] : 2013/10/23 20:15:13 => FATAL: [test] @ /var/log/ruby/app/foo.log</span>
</p>


* <span class="method">date\_format [= format]</span>  
<div class="param_header">Parameters</div>  
  * <span class="type">String</span> <span class="param">format</span>  
ログをファイルに出力する時の $DATE のフォーマットを指定します。  
format の書式は、Date#strftime(format) の引数と一緒です。  
デフォルトは "%Y/%m/%d %H:%M:%S" ですので、2013/10/04 20:04:59 のように日付は出力されます。  
値を定義しない場合は現在値を返却します。  
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log", "DAILY")
logger.date\_format = "%y/%m/%d - %H:%M:%S"
</p>

* <span class="method">rename\_format [= format]</span>  
<div class="param_header">Parameters</div>  
  * <span class="type">String</span> <span class="param">format</span>  
ログファイルがローテーションされる際、  
ファイルは file\_name.1 や file\_name.20131024 というふうにリネームされます。  
このドットの部分をここで指定する任意の文字列に変更できます。  
デフォルトは '.' です。  
値を定義しない場合は現在値を返却します。  
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log", "1G")
logger.rename\_format = ".foo."
  <span class="em">\# => file\_name.foo.1 のようにリネームされます。</span>
</p>


* <span class="method">no\_wcheck</span>  
\#w メソッド実行時にローテーションを行うべきかチェックを行いません。  
従って #w メソッド実行によってファイルのローテーションは行われません。  

* <span class="method">file\_closed?</span>  
ログファイルが閉じているかどうかを bool値で返却します。   
\#init のパラメータ file\_name  に :STDOUT を指定した場合は nilを返します。    

* <span class="method">silence</span>  
WARNINGメッセージを出力しないようにします。  
WARNINGメッセージとは SimpleRotate内部で予期せぬ状況が発生した時に標準エラー出力に吐かれる下記のようなメッセージです。  
例: [WARNING] File is already open! - (SimpleRotate::Error)  

* <span class="method">debug</span>  
ログレベルを "DEBUG" にします。  
self を返すのでメソッドチェインで #w につなげます。  
"DEBUG" はデバッグ用のメッセージです。  

* <span class="method">info</span>  
ログレベルを "INFO" にします。  
self を返すのでメソッドチェインで #w につなげます。  
"INFO" はプログラム上の情報です。  

* <span class="method">warn</span>  
ログレベルを "WORN" にします。  
self を返すのでメソッドチェインで #w につなげます。  
"WARN" は深刻なエラーではありませんが警告を促すメッセージです。  

* <span class="method">error</span>  
ログレベルを "ERROR" にします。  
self を返すのでメソッドチェインで #w につなげます。  
"ERROR" はエラーを知らせるメッセージです。  

* <span class="method">fatal</span>  
ログレベルを "FATAL" にします。  
self を返すのでメソッドチェインで #w につなげます。  
"FATAL" はプログラムが停止するような致命的なエラーメッセージです。    
<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.init("/var/log/ruby/app/foo.log")
logger.warn << "log message"
logger << "log message" <span class="em"># 省略してもログレベルは"WORN"を引き継ぎます。</span>
logger.fatal << "log message"
logger << "log message" <span class="em"># 省略してもログレベルは"FATAL"を引き継ぎます。</span>
<span style="color: yellow;">
[2013/12/16 14:15:03] - WARN : log message
[2013/12/16 14:15:03] - WARN : log message
[2013/12/16 14:15:03] - FATAL : log message
[2013/12/16 14:15:03] - FATAL : log message
</span>
</p>

* <span class="method">sleep\_time [= Integer]</span>   
ローテーションが終わった後に停止する時間を秒で指定します。  
これはマルチスレッド、マルチプロセスの際に重要です。  
シングルで動かす場合は特に呼び出すメリットはありません。  
また、#psafe_mode のパラメータでも指定可能です。  


* <span class="method">psafe\_mode(sleep\_time=0.1)</span>  
プロセスセーフモードです。  
\#init にクリティカルセクションがある為 #init の前に行うべきです。  
詳しくは<a href="#multi">マルチプロセス、マルチスレッドについて</a>をご覧ください。  
<div class="param_header">Parameters</div>
  * <span class="type">Integer</span> <span class="param">sleep\_time</span>   
ローテーションが終わった後に停止する時間を秒で指定します。  
デフォルトは 0.1秒です。  
もしマルチプロセスで複数のプロセスが同時にローテーションを行ってしまう場合はこの値を大きくしてみてください。  
実際にリネームが行われるまでのオーバーヘッドを考慮しての事です。   

<p class="ex"><span class="eh">Example:</span>
logger = SimpleRotate.instance
logger.psafe_mode(3)
logger.init("/var/log/ruby/app/foo.log")
</span>
</p>

* <span class="method">sync\_inode</span>  
現在開いているファイルの inode番号と #initメソッドの file\_nameで指定したファイルの inode番号を比較し、  
差異を確認した場合 file\_nameで指定したファイルを開き直します。  
これは #wメソッド呼び出し時に自動で行われるのであまり意識して呼び出すメソッドではありません。  
inode番号に差異があった場合、何らかの原因で inode番号を取得できない場合は  
最大で3回開き直し、それでもinode番号が一致しなければエラーメッセージを出力し、falseを返します。  
\#no\_sync\_inodeを呼び出した後は inode番号の確認を行わず常に nilを返して終了します。  
上記以外の場合で標準出力にのみログを出力するようにしている場合はエラーメッセージを出力し nilを返して終了します。   
それ以外では trueを返します。 


* <span class="method">no\_sync\_inode</span>  
現在開いているファイルの inode番号と #initメソッドの file\_nameで指定したファイルの inode番号を比較しません。  
シングルスレッド、シングルプロセス時に使用すべきです。  


<h2 class="header">Class</h2>
### SimpleRotate::Error
> SimpleRotateライブラリ内での例外を取り扱う内部クラスです。  
> 基本的に SimpleRotate内部で発生し得るエラーはこの例外です。  

### SimpleRotate::ProcessSync
> プロセスセーフの為の内部クラスです。  
> SimpleRotate::ProcessSyncMixin を Mix-inしています。

<h2 class="header">Module</h2>
> SimpleRotateライブラリ内で使用するモジュールです。  
### SimpleRotate::LogLevel
### SimpleRotate::RotateTerm
### SimpleRotate::ProcessSyncMixin
### SimpleRotate::Validator


<h2 class="header">Required</h2>
> requireされている標準添付ライブラリです。
### singleton
### monitor
### zlib
