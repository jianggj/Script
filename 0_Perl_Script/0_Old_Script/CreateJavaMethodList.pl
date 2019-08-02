#********************************************************************************************************
#FileName:CreateJavaMethodList.pl
#Description:プロジェクトディレクトリの配下にJAVAメソッド一覧を取得するツール
#********************************************************************************************************

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Next;
use Encode;

my $RESOURCES_DIR = dirname(dirname(__FILE__));
# デバッグ用
#my $RESOURCES_DIR = "D://SVN//kokuho//source//GUI";

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#                                    検索用フィルタの設定
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# デバッグログを出力するモード
# 0:出力しない
# 1:出力する
my $DEBUG_MODE = "0";

# トップメソッドまたは全部メソッドを出力するかどうかを取り決めるフラグ
# 0:全部メソッド
# 1:トップメソッド
my $TOP_METHOD_EXTRACT_FLAG = "0";

# ホワイト・リスト
# 抽出可能なメソッドの名前を設定する
my @WHITELIST_METHOD_NAME=("init","checkInput","doPre","doMain","doPost","execute");

# 抽出可能なメソッドのタイプ
# デフォルト値：【public|private|protected】
# publicのみ抽出したい場合、下記のように、"public"を設定ください
# my $WHITELIST_METHOD_TYPE = "public";
my $WHITELIST_METHOD_TYPE = "public|private|protected";
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 抽出されたJAVAメソッドを格納するハッシュ
my %javaMethodListHash = ();
# 出力されたJAVAメソッド一覧CSVファイルの名前
my $JAVA_METHODLIST_FILE_NAME="JAVA_METHOD_LIST_FILE.csv";
# 出力されたJAVAメソッド一覧CSVファイルの格納箇所
my $JAVA_METHODLIST_FILE_OUTPUT_PATH="$RESOURCES_DIR//properties//$JAVA_METHODLIST_FILE_NAME";

# GUI環境設定画面にて指定された機能に関するJAVA METHOD一覧を取得し、JAVA_METHOD_LIST_FILE.csvに出力する
&createJavaMethodList();

#*******************************************************************************
#Function Name:createJavaMethodList()
#Description:GUI環境設定画面にて指定された機能に関するJAVA METHOD一覧を取得する
#*******************************************************************************
sub createJavaMethodList() {

  #logファイルを開く
  &logopen();
  &logout( "INFO", "createJavaMethodList START.", __LINE__ );

  my $remain;
  my $comment = 0;
  my $data;
  my $line;
  my @lines;

  # プロジェクトディレクトリからGUI環境設定画面にて指定された機能一覧を取得する
  my ($packagenameOutputFlag, $javaFunctionList) = &getPathFromProperties();

  eval{
    # JAVAメソッド一覧CSVファイルを開く
    open JAVA_METHODLIST_FILE,">$JAVA_METHODLIST_FILE_OUTPUT_PATH" or
    die "Cannot open $JAVA_METHODLIST_FILE_OUTPUT_PATH: $!";
  };
  if($@){
    &logout("ERROR","ファイルの読み書きに例外が発生しました。【Method：createJavaMethodList 詳細：$@】", __LINE__);
    die "ファイルの読み書きに失敗しました。";
  }

  #GUI環境設定画面にて指定された機能フォルダが存在するかどうかをチェックする
  foreach my $javaSourceDir(@$javaFunctionList){
    &logout("DEBUG","【GUI環境設定画面にて指定された機能フォルダ：$javaSourceDir】",__LINE__);
    unless ( -e $javaSourceDir ) {
      &logout("ERROR","該当フォルダが存在していません。【Method：Main 詳細：$javaSourceDir】",
        __LINE__);
      die "$javaSourceDirフォルダが存在していません。";
    }

    # GUI環境設定画面にて指定されたJAVA機能フォルダをコメントとして、「JAVA_METHOD_LIST_FILE.csv」ファイルに出力する
    print JAVA_METHODLIST_FILE "#$javaSourceDir\n";

    # GUI環境設定画面にて指定された機能フォルダ一覧ごとに、すべてjavaソースを検索する
    my $files = File::Next::files({file_filter =>\&java_file_filter,
                                   descend_filter => \&descend_filter}, $javaSourceDir);

    # 検索されたJAVAソースごとに、下記の処理を行う
    while ( defined( my $file = $files->() ) ) {
      unless ( -e $file ) {
        &logout("ERROR","該当するファイルが存在していません。【Method：createJavaMethodList 詳細：$file】", __LINE__);
        next;
      }

      eval {
        $data = "";
         # 該当するJAVAソースを開く
         open IN, "$file" or die "Can't open '$file': $!";
         # 該当するJAVAソースの内容を$lineに格納する
         $line = do { local $/; <IN> };
         close IN;
         # 該当するJAVAソースの内容があった場合
         if ($line){
           # 該当するJAVAソースに改行コードを文字列「CR_LF_SPLITSTRING」に置換する
           $line =~ s/\r|\r\n|\n/CR_LF_SPLITSTRING/g;
           # 文字列「CR_LF_SPLITSTRING」によって、行ごとにソースを配列@linesに格納する
           @lines = split /CR_LF_SPLITSTRING/ , $line;
         }
         # JAVAソースのコメントを除いて、ソース本体を取得して、$dataに格納する
         $data = deleteCommentFromJavaSource(\@lines);
      };
      if ($@) {
        #ログファイルに出力する
        &logout("ERROR","ファイルの読み込みに例外が発生しました。【Method：createJavaMethodList 詳細：$@】", __LINE__);
        next;
      }

      my $packageName="";
      my $className="";
      my $methodName="";

      # 取得されたJAVAソースから、パッケージ名を取得する
      if ( $packagenameOutputFlag eq "1" && $data =~/package\s+((\w+\.)*\w+)\;/ ) {
        $packageName = "$1.";
      }
      # 取得されたJAVAソースから、クラス名を取得する
      if ( $data =~/($WHITELIST_METHOD_TYPE)\s*(\w+)*\s*(?:class|interface)\s*(\w+)\b/ ) {
        $className = $3;
      }

      # 取得されたJAVAソースから、メソッド名を取得する
      if ($className){
        my @sourceLines = split /;/ , $data;
        foreach my $sourceLine (@sourceLines){
          next unless $sourceLine =~/(?:public|private|protected)\s+/;
          s/(?:public|private|protected)\s+(?:\w+\s+)*=(.*);\s*$//g;
          while ( $sourceLine =~s/(?:(?:public|private|protected)\s+)+(?:(?:(?:abstract|final|native|transient|static|synchronized)\s+)*(?:<(?:\?|[A-Z]\w*)(?:\s+(?:extends|super)\s+[A-Z]\w*)?(?:(?:,\s*(?:\?|[A-Z]\w*))(?:\s+(?:extends|super)\s+[A-Z]\w*)?)*>\s+)?(?:(?:(?:[A-Z]\w*(?:<[A-Z]\w*>)?|[A-Z]\w*<[A-Z]\w*\s*,\s*[A-Z]\w*<[A-Z]\w*>>|int|float|double|char|byte|long|short|boolean|void)(?:(?:\[\]))*)|void)+)\s*(<.*?>)*\s*(?:<\w+\s*(?:,\s*\w+\s*)*>)*\s*(\w+)\s*\(//) {
            $methodName = $&;
            $methodName =~s/.*\s+(\w+)\s*(\r\n)*\s*\(/$1/;
            if ($methodName){
              # メソッドホワイトリストに抽出可能なメソッド名がある場合
              if ($TOP_METHOD_EXTRACT_FLAG eq "1" && scalar @WHITELIST_METHOD_NAME > 0){
                # JAVAソースから取得されたメソッド名がメソッドホワイトリストに存在しなかった場合、該当メソッドを出力しない。
                next unless ( grep {$_ eq $methodName} @WHITELIST_METHOD_NAME );
                if (! exists $javaMethodListHash{$packageName.$className.$methodName} ) {
                  print JAVA_METHODLIST_FILE "$packageName$className,$methodName\n";
                  $javaMethodListHash{$packageName.$className.$methodName} = 1;
                }
              }else{
                # メソッドホワイトリストに抽出可能なメソッド名がない場合、該当メソッドをCSVファイルに出力する。
                if (! exists $javaMethodListHash{$packageName.$className.$methodName} ) {
                  print JAVA_METHODLIST_FILE "$packageName$className,$methodName\n";
                  $javaMethodListHash{$packageName.$className.$methodName} = 1;
                }
              }
            }else{
              &logout("ERROR","METHOD名抽出に例外が発生しました。【ファイル名：$file】【パッケージ名：$packageName】【クラス名：$className】【METHOD名：$methodName】",__LINE__);
            }
          }
        }
      }else{
        &logout("ERROR","パッケージ・クラス抽出に例外が発生しました。【ファイル名：$file】【パッケージ名：$packageName】【クラス名：$className】",__LINE__);
      }
    }
  }

  close JAVA_METHODLIST_FILE;
  &logout( "INFO", "createJavaMethodList END.", __LINE__ );
  &logclose();
}

#*************************************************************
#Function Name:logopen()
#Description:ログファイルを開く
#*************************************************************
sub logopen() {
  my $guiLogFile = "$RESOURCES_DIR//CrudCreator.log";
  open( GUI_LOG_FILE, ">>$guiLogFile" );
}

#*************************************************************
#Function Name:logclose()
#Description:ログファイルを閉める
#*************************************************************
sub logclose() {
  close GUI_LOG_FILE;
}

#*************************************************************
#Function Name:logout()
#Description:ログファイルに出力する
#Parameters:ログ分類(DEBUG,INFO,ERROR)、出力するログメッセージ、行目
#*************************************************************
sub logout(@) {
  # パラメータを取得する
  my ( $logType, $logMsg, $line ) = @_;

  my $year;
  my $mon;
  my $mday;
  my $hour;
  my $min;
  my $sec;
  my $str_time;
  my $currentSourceName = "CreateJavaMethodList.pl";

  # ログタイプが省略時は"INFO"を設定
  if ( length($logType) == 0 ) {
    $logType = "INFO";
  }

  # 日、月、年、週のみを取得する
  ( $mday, $mon, $year ) = ( localtime(time) )[ 3 .. 5 ];
  # 秒、分、時のみを取得する
  ( $sec, $min, $hour ) = ( localtime(time) )[ 0 .. 2 ];
  $year += 1900;
  $mon  += 1;
  $str_time = sprintf( "%4d-%02d-%02d %02d:%02d:%02d,%03d",
              $year, $mon, $mday, $hour, $min, $sec, "000");
  $logMsg=~s/\n//;

  #エンコードはUTF-8に変更する
  $logMsg = encode("UTF-8", decode("shiftjis",$logMsg) );
  # ログファイル追加モードでオープン
  if ( ( uc($logType) eq "DEBUG" ) && ( $DEBUG_MODE eq "1" ) ) {
    printf( GUI_LOG_FILE "%s %s %d %s: %s\n",
    $str_time, $currentSourceName, $line, uc($logType), $logMsg );
  }
  elsif ( uc($logType) eq "INFO" ) {
    printf( GUI_LOG_FILE "%s %s %d %s: %s\n",
    $str_time, $currentSourceName, $line, uc($logType), $logMsg );
  }
  elsif ( uc($logType) eq "ERROR" ) {
    printf( GUI_LOG_FILE "%s %s %d %s: %s\n",
    $str_time, $currentSourceName, $line, uc($logType), $logMsg );
  }
}

#*************************************************************
#Function Name:getPathFromProperties()
#Description:解析出力結果格納箇所、解析先SOURCEディレクトリを取得
#*************************************************************
sub getPathFromProperties(){
  # パッケージ名を出力するかどうかを取り決めるフラグ
  # 0:パッケージ名を出力しない
  # 1:パッケージ名を出力する
  my $packagenameOutputFlag;
  # propertiesファイルのJAVA_FUNCTION_LIST配列
  my @javaFunctionList;

  # 設定ファイル「CrudCreator.properties」の格納箇所
  my $propertiesPath = "$RESOURCES_DIR//properties//CrudCreator.properties";

  &logout("DEBUG","【環境設定ファイル名：$propertiesPath】",__LINE__);

  unless (-e $propertiesPath){
    &logout("ERROR","環境設定ファイルは存在していません。ファイルパス：「$propertiesPath」",__LINE__);
    die "環境設定ファイルは存在していません。ファイルパス：「$propertiesPath」";
  }
  eval{
    open PROPERTIES,$propertiesPath or die "ファイルの読み込みに失敗しました。";
    while(<PROPERTIES>){
      if(/^PACKAGENAME_OUTPUT_FLAG=(.*)$/){
        $packagenameOutputFlag = $1;
      }elsif(/^JAVA_FUNCTION_LIST(_\d+)*=(.*)$/){
        # propertiesファイルからJAVA_FUNCTION_LIST配列を取得する
        push @javaFunctionList,$2;
      }
    }
    close PROPERTIES;
  };
  if($@){
    &logout("ERROR","環境設定ファイルの読み込みに失敗しました。【詳細：$@】",__LINE__);
    die "環境設定ファイルの読み込みに失敗しました。";
  }
  return $packagenameOutputFlag, \@javaFunctionList;
}

#*************************************************************
#Function Name:deleteCommentFromJavaSource()
#Description:JAVAソースのコメントを除いて、ソース本体を取得
#*************************************************************
sub deleteCommentFromJavaSource($){
  my $lines = shift;

  my $data;
  my $comment = 0;
  my $remain;

  foreach my $splitLine (@$lines) {
    $_ = $splitLine;

    #改行コードを除く
    chomp;

    #行頭の空文字を除く
    s/^\s+//g;
    #行尾の空文字を除く
    s/\s+$//g;
    if (/^\s*(\/\/.*)?$/) {
      next;
    }
    #remove comment or space after line
    if (/\s*(\/\/.*)?$/) {
      $_ = $`;
    }
    if (/\/\*.*\*\//) {
      $_ = "$`$'";
    }
    #block comment
    if ( $comment == 0 ) {
      if (/\/\*/) {
        $remain .= $`;
        $comment = 1;
        next;
      }
    }
    else {
      if (/\*\//) {
        $_ = "$remain$'";
        $remain  = "";
        $comment = 0;
      }
      else {
        next;
      }
    }
    $data .= "$_ ";
  }

  return $data;
}

#*************************************************************
#Function Name:java_file_filter()
#Description:JAVAソースのみを出力するフィルタ
#*************************************************************
sub java_file_filter {
    # 呼び出し元：File::Next:files.
    # JAVAソースのみを出力するフィルタ
    /.(java)$/
}

#*************************************************************
#Function Name:descend_filter()
#Description:SVNファイルを出力しないフィルタ
#*************************************************************
sub descend_filter {
    # 呼び出し元：File::Next:files.
    # SVNファイルを出力しないフィルタ
    $File::Next::dir !~ /.svn$/
}

1;
