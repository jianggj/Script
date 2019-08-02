#********************************************************************************************************
#FileName:SearchFunctionIsNeverUsed.pl
#Description:プロジェクトディレクトリの配下にCメソッド一覧を取得し、呼び出さないものを抽出するツール
#********************************************************************************************************

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Next;
use Encode;

# 本ツールの格納箇所
my $RESOURCES_DIR = dirname(__FILE__);

# デバッグログを出力するモード
# 0:出力しない
# 1:出力する
my $DEBUG_MODE = "0";

# 抽出されたCメソッドを格納するハッシュ
my %cMethodListHash = ();

# 抽出された呼び出されたCメソッドを格納するハッシュ
my %cMethodCalledListHash = ();

# 出力された呼び出さないメソッド一覧の格納箇所
my $FUNCTION_NAME_IS_NEVER_USED_CSV_FILE_PATH="$RESOURCES_DIR¥¥FUNCTION_IS_NEVER_USED¥¥FUNCTION_NAME_IS_NEVER_USED.csv";

# 出力された呼び出さないメソッド一覧および規模のCSVファイルの格納箇所
my $FUNCTION_INFO_IS_NEVER_USED_CSV_FILE_PATH="$RESOURCES_DIR¥¥FUNCTION_IS_NEVER_USED¥¥FUNCTION_INFO_IS_NEVER_USED.csv";

# 出力された呼び出さないメソッド一覧および規模のCSVファイルの格納箇所
my $FUNCTION_INFO_TMP_CSV_FILE_PATH="$RESOURCES_DIR¥¥FUNCTION_IS_NEVER_USED¥¥FUNCTION_INFO_TMP.csv";

# 出力された呼び出さないメソッド一覧および規模のCSVファイルの格納箇所
my $DECLARATION_FUNCTION_LIST_CSV_FILE_PATH="$RESOURCES_DIR¥¥FUNCTION_IS_NEVER_USED¥¥DECLARATION_FUNCTION_LIST.csv";

# 出力されたメソッド一覧CSVファイルの格納箇所
my $SEARCH_target_SOURCE_PATH = "";

# 正式表現式（関数の宣言をマッチする）
my $REGEXSTRING_FUNCTION_DECLARATION = "";

# 正式表現式（関数の呼び出す文字列をマッチする）
my $REGEXSTRING_FUNCTION_CALL = "";

#パラメータを取得する
if(@ARGV == 1){
  $SEARCH_target_SOURCE_PATH = shift;
}

unless(-d "$RESOURCES_DIR¥¥FUNCTION_IS_NEVER_USED"){
  mkdir("$RESOURCES_DIR¥¥FUNCTION_IS_NEVER_USED");
}

#パースパース末尾に¥¥がない場合¥¥を追加
unless ( $SEARCH_target_SOURCE_PATH =~ /¥¥$/ ) {
  $SEARCH_target_SOURCE_PATH = "$SEARCH_target_SOURCE_PATH¥¥";
}

#logファイルを開く
&logopen();
&logout( "INFO", "SearchFunctionIsNeverUsed START.", __LINE__ );

unless ( -e $SEARCH_target_SOURCE_PATH ) {
  &logout("ERROR","解析先対象フォルダが存在していません。【Method：Main 詳細：$SEARCH_target_SOURCE_PATH】",
    __LINE__);
  die "解析先対象フォルダが存在していません。【Method：Main 詳細：$SEARCH_target_SOURCE_PATH】";
}

# プロジェクトディレクトリの配下にCメソッド一覧を取得し、呼び出さないものを抽出するツール
&SearchFunctionIsNeverUsed();

&logout( "INFO", "SearchFunctionIsNeverUsed END.", __LINE__ );

&logclose();

#**********************************************************************************************
#Function Name:SearchFunctionIsNeverUsed()
#Description:プロジェクトディレクトリの配下にCメソッド一覧を取得し、呼び出さないものを抽出する
#**********************************************************************************************
sub SearchFunctionIsNeverUsed() {

  my $line;
  my @lines;
  my $sourceContents;
  my $sourceContentsLeft;

  my $functionName = "";
  my $arguments = "";
  my $returnType = "";

  eval{
    # 呼び出さないCメソッド情報一覧CSVファイルを開く
    open FUNCTION_INFO_IS_NEVER_USED_CSV_FILE_PATH,">$FUNCTION_INFO_IS_NEVER_USED_CSV_FILE_PATH" or
    die "Cannot open $FUNCTION_INFO_IS_NEVER_USED_CSV_FILE_PATH: $!";
  };
  if($@){
    &logout("ERROR","ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】", __LINE__);
    die "ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】";
  }

  eval{
    # 呼び出さないCメソッドリスト一覧CSVファイルを開く
    open FUNCTION_NAME_IS_NEVER_USED_CSV_FILE_PATH,">$FUNCTION_NAME_IS_NEVER_USED_CSV_FILE_PATH" or
    die "Cannot open $FUNCTION_NAME_IS_NEVER_USED_CSV_FILE_PATH: $!";
  };
  if($@){
    &logout("ERROR","ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】", __LINE__);
    die "ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】";
  }

  eval{
    # 呼び出さないCメソッドリスト一覧CSVファイルを開く
    open FUNCTION_INFO_TMP_CSV_FILE_PATH,">$FUNCTION_INFO_TMP_CSV_FILE_PATH" or
    die "Cannot open $FUNCTION_INFO_TMP_CSV_FILE_PATH: $!";
  };
  if($@){
    &logout("ERROR","ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】", __LINE__);
    die "ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】";
  }

  eval{
    # 呼び出さないCメソッドリスト一覧CSVファイルを開く
    open DECLARATION_FUNCTION_LIST_CSV_FILE_PATH,">$DECLARATION_FUNCTION_LIST_CSV_FILE_PATH" or
    die "Cannot open $DECLARATION_FUNCTION_LIST_CSV_FILE_PATH: $!";
  };
  if($@){
    &logout("ERROR","ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】", __LINE__);
    die "ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】";
  }

  # パラメーターに指定されたフォルダにすべてC言語のソースを検索する
  my $files = File::Next::files({file_filter =>¥&c_file_filter,
                                 descend_filter => ¥&descend_filter}, $SEARCH_target_SOURCE_PATH);

  # 検索されたC言語のソースごとに、下記の処理を行う
  while ( defined( my $file = $files->() ) ) {
    unless ( -e $file ) {
      &logout("ERROR","該当するファイルが存在していません。【Method：SearchFunctionIsNeverUsed 詳細：$file】", __LINE__);
      next;
    }

#unless($file =~ /JSGCR_com_423CheckShoboryokuCar.c/){
#  next;
#}
#print "$file¥n";
    $sourceContentsLeft = "";
    &logout("DEBUG","METHOD宣言の抽出。【ファイル名：$file】",__LINE__);
    eval {
      $sourceContents = "";
       # 該当するCソースを開く
       open IN, "$file" or die "Can't open '$file': $!";
       # 該当するCソースの内容を$lineに格納する
       $line = do { local $/; <IN> };
       close IN;
       # 該当するCソースの内容があった場合
       if ($line){
         # 該当するCソースに改行コードを文字列「CR_LF_SPLITSTRING」に置換する
         $line =~ s/¥r|¥r¥n|¥n|¥cJ|¥cM/CR_LF_SPLITSTRING/g;
         $line =~ s/¥cI/ /g;
         # 文字列「CR_LF_SPLITSTRING」によって、行ごとにソースを配列@linesに格納する
         @lines = split /CR_LF_SPLITSTRING/ , $line;
       }
       # C言語のソースのコメントを除いて、ソース本体を取得して、$sourceContentsに格納する
       $sourceContents = deleteCommentFromClanguageSource(¥@lines);
    };
    if ($@) {
      #ログファイルに出力する
      &logout("ERROR","ファイルの読み込みに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】", __LINE__);
      next;
    }

    if ($file =~ /(¥.c)|(¥.pc)$/){
      $REGEXSTRING_FUNCTION_DECLARATION = '(((?:static¥s+)?¥w+(?:¥*)*)¥s+((?:¥*)*¥w+)¥s*¥(([^)]*)¥)¥s*¥{)';
      $REGEXSTRING_FUNCTION_CALL = '(?:(¥w+)¥s*¥(([^()]|¥([^()]*¥))*¥)¥s*)+?(?=;|,|¥||¥)|&|¥¥|>|<|=|!)';
    }elsif($file =~ /¥.h$/){
      $REGEXSTRING_FUNCTION_DECLARATION = '(((?:¥w+¥s+)?¥w+(?:¥*)*)¥s+((?:¥*)*¥w+)¥s*¥(([^)]*)¥)¥s*$)';
    }

    # 取得されたC言語のソースから、メソッド名を取得する
    my @sourceLines = split /;/ , $sourceContents;
    foreach my $sourceLine (@sourceLines) {
      while ( $sourceLine =~s/$REGEXSTRING_FUNCTION_DECLARATION//) {
        $functionName = trim($3);
        $arguments = trim($4);
        $returnType = trim($2);

        if ($functionName){
          if ( ( $functionName eq "if" )
            || ( $functionName eq "main" )
            || ( $functionName eq "for" )
            || ( $functionName eq "while" )
            || ( $functionName eq "switch" )
            || ( $functionName eq "case" )
            || ( $functionName eq "int" )
            || ( $functionName eq "char" )
            || ( $functionName eq "flaot" )
            || ( $functionName eq "double" )
            || ( $functionName eq "long" )
            || ( $functionName eq "short" )
            || ( $functionName eq "bit" )
            || ( $functionName eq "unsigned" )
            || ( $functionName eq "return" ) ) {
            next;
          }

          if (! exists $cMethodListHash{$functionName} ) {
            $cMethodListHash{$functionName} = $file;
            print DECLARATION_FUNCTION_LIST_CSV_FILE_PATH "$functionName¥n";
          }else{
            $cMethodListHash{$functionName} .= "_FILE_SPLIT_STRING_$file";
          }
        }else{
          &logout("ERROR","METHOD宣言の抽出に例外が発生しました。【ファイル名：$file】",__LINE__);
        }
      }
      $sourceContentsLeft .= "$sourceLine;";
    }
return;
    $sourceContentsLeft =~ s/(¥w+_(?:OnTrace|OnDebug|OnError))/_$1/g;
    $sourceContentsLeft =~ s/#define¥s*__FUNC__¥s*"¥w+"//g;
    $sourceContentsLeft =~ s/#include¥s*<.*?>//g;
    $sourceContentsLeft =~ s/#include¥s*".*?"//g;

    print FUNCTION_INFO_TMP_CSV_FILE_PATH "$sourceContentsLeft¥n";

    while ( $sourceContentsLeft =~s/¥(¥s*¥w+¥(¥s*¥*¥s*¥)¥(¥s*¥)¥s*¥)(¥w+)//) {
      my $functionCallName = trim($1);
      if ($functionCallName){
        if (! exists $cMethodCalledListHash{$functionCallName} ) {
          $cMethodCalledListHash{$functionCallName} = 1;
        }
      }else{
        &logout("ERROR","METHOD名抽出に例外が発生しました。【ファイル名：$file】【関数名：$functionCallName】",__LINE__);
      }
    }

    while ( $sourceContentsLeft =~s/$REGEXSTRING_FUNCTION_CALL//) {
      my $functionCallName = trim($1);
      if ( ( $functionCallName eq "if" )
        || ( $functionCallName eq "for" )
        || ( $functionCallName eq "main" )
        || ( $functionCallName eq "while" )
        || ( $functionCallName eq "switch" )
        || ( $functionCallName eq "case" )
        || ( $functionCallName eq "int" )
        || ( $functionCallName eq "char" )
        || ( $functionCallName eq "flaot" )
        || ( $functionCallName eq "double" )
        || ( $functionCallName eq "long" )
        || ( $functionCallName eq "short" )
        || ( $functionCallName eq "bit" )
        || ( $functionCallName eq "unsigned" )
        || ( $functionCallName eq "exit" )
        || ( $functionCallName eq "printf" )
        || ( $functionCallName eq "sizeof" )
        || ( $functionCallName eq "NVL" )
        || ( $functionCallName eq "memset" )
        || ( $functionCallName eq "memcpy" )
        || ( $functionCallName eq "VL" )
        || ( $functionCallName eq "TO_CHAR" )
        || ( $functionCallName eq "return" ) ) {
        next;
      }

      if ($functionCallName){
        if (! exists $cMethodCalledListHash{$functionCallName} ) {
          $cMethodCalledListHash{$functionCallName} = 1;
        }
      }else{
        &logout("ERROR","METHOD名抽出に例外が発生しました。【ファイル名：$file】【関数名：$functionCallName】",__LINE__);
      }
    }
  }
  close FUNCTION_INFO_TMP_CSV_FILE_PATH;

  # 該当するCソースの内容を$lineに格納する
  open IN, "$FUNCTION_INFO_TMP_CSV_FILE_PATH" or die "Can't open '$FUNCTION_INFO_TMP_CSV_FILE_PATH': $!";
  my $sourceLineTemp = do { local $/; <IN> };
  close IN;

  foreach(keys %cMethodListHash) {
    my $funcName = $_;
    my $funcFileName = $cMethodListHash{$funcName};

    if ($funcName =~/^¥*(¥w+)/){
      $cMethodCalledListHash{$funcName} = 1;
    }

    if ( ! exists $cMethodCalledListHash{$funcName} && $sourceLineTemp !~/¥b¥Q$funcName¥E¥b/ ) {
      print FUNCTION_NAME_IS_NEVER_USED_CSV_FILE_PATH "$funcName¥n";
      my @funcFileNames = split /_FILE_SPLIT_STRING_/ , $funcFileName;
      foreach my $funcFileNameSplit (@funcFileNames) {
        if(-f $funcFileNameSplit){
          my $resultStr = getFunctionLineNum($funcFileNameSplit,$funcName);
          if ($resultStr){
            print FUNCTION_INFO_IS_NEVER_USED_CSV_FILE_PATH "$resultStr¥n";
          }else{
           &logout("ERROR","METHOD名の行番号の取得に例外が発生しました。【ファイル名：$funcFileNameSplit】【関数名：$funcName】",__LINE__);
          }
        }
      }
    }
#    elsif($sourceLine =~/¥b¥Q$funcName¥E¥b/) {
#
#    }
  }
  close DECLARATION_FUNCTION_LIST_CSV_FILE_PATH;
  close FUNCTION_NAME_IS_NEVER_USED_CSV_FILE_PATH;
  close FUNCTION_INFO_IS_NEVER_USED_CSV_FILE_PATH;
}

#*************************************************************
#Function Name:logopen()
#Description:ログファイルを開く
#*************************************************************
sub logopen() {
  my $logFile = "$RESOURCES_DIR¥¥FUNCTION_IS_NEVER_USED¥¥SEARCH_FUNCTION_IS_NEVER_USED.log";
  open( LOG_FILE, ">>$logFile" );
}

#*************************************************************
#Function Name:logclose()
#Description:ログファイルを閉める
#*************************************************************
sub logclose() {
  close LOG_FILE;
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
  my $currentSourceName = "SearchFunctionIsNeverUsed.pl";

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
  $logMsg=~s/¥n//;

  #エンコードはUTF-8に変更する
  $logMsg = encode("UTF-8", decode("shiftjis",$logMsg) );
  # ログファイル追加モードでオープン
  if ( ( uc($logType) eq "DEBUG" ) && ( $DEBUG_MODE eq "1" ) ) {
    printf( LOG_FILE "%s %s %d %s: %s¥n",
    $str_time, $currentSourceName, $line, uc($logType), $logMsg );
  }
  elsif ( uc($logType) eq "INFO" ) {
    printf( LOG_FILE "%s %s %d %s: %s¥n",
    $str_time, $currentSourceName, $line, uc($logType), $logMsg );
  }
  elsif ( uc($logType) eq "ERROR" ) {
    printf( LOG_FILE "%s %s %d %s: %s¥n",
    $str_time, $currentSourceName, $line, uc($logType), $logMsg );
  }
}

#*************************************************************
#Function Name:deleteCommentFromClanguageSource()
#Description:C言語のソースのコメントを除いて、ソース本体を取得
#*************************************************************
sub deleteCommentFromClanguageSource($){
  my $lines = shift;

  my $sourceContents;
  my $comment = 0;
  my $remain;

  foreach my $splitLine (@$lines) {
    $_ = $splitLine;

    #改行コードを除く
    chomp;

    #行頭の空文字を除く
    s/^¥s+//g;
    #行尾の空文字を除く
    s/¥s+$//g;
    if (/^¥s*(¥/¥/.*)?$/) {
      next;
    }
    #remove comment or space after line
    if (/¥s*(¥/¥/.*)?$/) {
      $_ = $`;
    }
    if (/¥/¥*.*¥*¥//) {
      $_ = "$`$'";
    }
    #block comment
    if ( $comment == 0 ) {
      if (/¥/¥*/) {
        $remain .= $`;
        $comment = 1;
        next;
      }
    }
    else {
      if (/¥*¥//) {
        $_ = "$remain$'";
        $remain  = "";
        $comment = 0;
      }
      else {
        next;
      }
    }
    $sourceContents .= "$_ ";
  }

  return $sourceContents;
}

#*************************************************************
#Function Name:getFunctionLineNum()
#Description:C言語のソースのメソッドの行番号を取得
#*************************************************************
sub getFunctionLineNum($$){
  my $file = shift;
  my $functionName = shift;

  my $comment = 0;
  my $remain;
  my $lineNum = 0;
  my $sourcelineNum = 0;
  my $returnSting;
  my @lines;

  # 該当するCソースを開く
  open IN, "$file" or die "Can't open '$file': $!";
  # 該当するCソースの内容を$lineに格納する
  my $line = do { local $/; <IN> };
  close IN;
  # 該当するCソースの内容があった場合
  if ($line){
   # 該当するCソースに改行コードを文字列「CR_LF_SPLITSTRING」に置換する
   $line =~ s/¥r|¥r¥n|¥n|¥cJ|¥cM/CR_LF_SPLITSTRING/g;
   $line =~ s/¥cI/ /g;
   # 文字列「CR_LF_SPLITSTRING」によって、行ごとにソースを配列@linesに格納する
   @lines = split /CR_LF_SPLITSTRING/ , $line;
  }

  foreach my $splitLine (@lines) {
    $lineNum++;
    $_ = $splitLine;

    #改行コードを除く
    chomp;

    #行頭の空文字を除く
    #s/^¥s+//g;
    #行尾の空文字を除く
    s/¥s+$//g;
    if (/^¥s*(¥/¥/.*)?$/) {
      next;
    }
    #remove comment or space after line
    if (/¥s*(¥/¥/.*)?$/) {
      $_ = $`;
    }
    if (/¥/¥*.*¥*¥//) {
      $_ = "$`$'";
    }
    #block comment
    if ( $comment == 0 ) {
      if (/¥/¥*/) {
        $remain .= $`;
        $comment = 1;
        next;
      }
    }
    else {
      if (/¥*¥//) {
        $_ = "$remain$'";
        $remain  = "";
        $comment = 0;
      }
      else {
        next;
      }
    }

    if(/^ $/){
      next;
    }

    if ($file =~ /(¥.c)|(¥.pc)$/){
      if(/(((static¥s+)?¥w+(¥*)?)¥s+((¥*)?¥Q$functionName¥E)¥s*¥()/){
        $returnSting = $lineNum;
        $sourcelineNum++;
        next;
      }

      if ($sourcelineNum != 0){
        $sourcelineNum++;
        if(/^¥}¥s*$/){
          return "$file	$functionName	$returnSting	$sourcelineNum";
        }
      }
    }elsif($file =~ /¥.h$/){
      if(/(((?:¥w+¥s+)?¥w+(?:¥*)*)¥s+((?:¥*)*¥Q$functionName¥E)¥s*¥(([^)]*)¥)¥s*;$)/){
        return "$file	$functionName	$lineNum	1";
      }
    }
  }

  return "";
}

#*************************************************************
#Function Name:trim()
#Description:文字列に先頭または後ろのスペース・テーブルを除く
#*************************************************************
sub trim($) {
  my $string = shift;
  $string =~ s/^¥s+// if defined($string);
  $string =~ s/¥s+$// if defined($string);
  $string =~ s/^¥t+// if defined($string);
  $string =~ s/¥t+$// if defined($string);

  $string =~ s/¥t+/ /g if defined($string);
  $string =~ s/¥s+/ /g if defined($string);

  return $string;
}

#*************************************************************
#Function Name:c_file_filter()
#Description:Cソースのみを出力するフィルタ
#*************************************************************
sub c_file_filter {
    # 呼び出し元：File::Next:files.
    # C言語のソースのみを出力するフィルタ
    /¥.(c|h|pc)$/
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
