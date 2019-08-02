#********************************************************************************************************
#FileName:DeleteIf0.pl
#Description:プロジェクト配下にCメソッド一覧を取得し、#if0で囲むソースを削除する
#********************************************************************************************************
use strict;
use Encode;
use warnings;
use Data::Dumper;
use File::Next;
use File::Basename;
use File::Path;

# デバッグログを出力するモード
# 0:出力しない
# 1:出力する
my $DEBUG_MODE = "0";

# 本ツールの格納箇所
my $RESOURCES_DIR = dirname(__FILE__);

# 抽出対象の格納箇所
my $SEARCH_TARGET_SOURCE_PATH = "";
# 抽出結果の格納箇所
my $OUTPUT_PATH = "";

#logファイルを開く
&logopen();
&logout( "INFO", "DeleteIf0 START.", __LINE__ );

#パラメータを取得する
if(@ARGV != 2){
  my $msg = "パラメータ数が間違っている、パラメーター１（抽出対象の格納箇所）とパラメーター２（抽出結果の格納箇所）を入力してください。";
  &logout("ERROR",$msg, __LINE__);
  die "$msg";
}

$SEARCH_TARGET_SOURCE_PATH = shift;
$OUTPUT_PATH = shift;

#パース末尾に¥¥がない場合¥¥を追加
unless ( $SEARCH_TARGET_SOURCE_PATH =~ /¥¥$/ ) {
  $SEARCH_TARGET_SOURCE_PATH = "$SEARCH_TARGET_SOURCE_PATH¥¥";
}

unless(-d $OUTPUT_PATH){
  #mkdir($OUTPUT_PATH);
  mkpath($OUTPUT_PATH,0,0755);
}

#パース末尾に¥¥がない場合¥¥を追加
unless ( $OUTPUT_PATH =~ /¥¥$/ ) {
  $OUTPUT_PATH = "$OUTPUT_PATH¥¥";
}

unless ( -e $SEARCH_TARGET_SOURCE_PATH ) {
  &logout("ERROR","抽出対象の格納箇所が存在していません。【Method：Main 詳細：$SEARCH_TARGET_SOURCE_PATH】", __LINE__);
  die "解析先対象フォルダが存在していません。【Method：Main 詳細：$SEARCH_TARGET_SOURCE_PATH】";
}

eval{
  # 呼び出さないCメソッド情報一覧CSVファイルを開く
  open DELETE_IF0_LIST_CSV_FILE_PATH,">$OUTPUT_PATH¥¥DELETE_IF0_LIST.csv" or
  die "Cannot open $OUTPUT_PATH¥¥DELETE_IF0_LIST.csv: $!";
};
if($@){
  &logout("ERROR","ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】", __LINE__);
  die "ファイルの読み書きに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】";
}

print DELETE_IF0_LIST_CSV_FILE_PATH "¥"ファイル名¥",¥"開始行番号¥",¥"置換元¥",¥"置換先¥"¥n";

unless ( -e $OUTPUT_PATH ) {
  mkdir("$OUTPUT_PATH");
}

# プロジェクトディレクトリの配下にCメソッド一覧を取得し、呼び出さないものを抽出するツール
&DeleteIf0();

close DELETE_IF0_LIST_CSV_FILE_PATH;

&logout( "INFO", "DeleteIf0 END.", __LINE__ );
&logclose();

#**********************************************************************************************
#Function Name:DeleteIf0()
#Description:プロジェクトディレクトリの配下にCメソッド一覧を取得し、呼び出さないものを抽出する
#**********************************************************************************************
sub DeleteIf0() {

  my $line;
  my @lines;

  # パラメーターに指定されたフォルダにすべてC言語のソースを検索する
  my $files = File::Next::files({file_filter =>¥&c_file_filter,
                                 descend_filter => ¥&descend_filter}, $SEARCH_TARGET_SOURCE_PATH);

  # 検索されたC言語のソースごとに、下記の処理を行う
  while ( defined( my $file = $files->() ) ) {
    unless ( -e $file ) {
      &logout("ERROR","該当するファイルが存在していません。【Method：DeleteIf0 詳細：$file】", __LINE__);
      next;
    }

#unless($file =~ /JSCDO_SendFail.c/){
#  next;
#}
#print dirname($file);
#print "¥n";

    &logout("DEBUG","METHOD宣言の抽出。【ファイル名：$file】",__LINE__);
    eval {
      my @lineTemps;

      # 該当するCソースを開く
      open IN, "$file" or die "Can't open '$file': $!";
      # 該当するCソースの内容を$lineに格納する
      $line = do { local $/; <IN> };
      close IN;

      my $lineTemp = $line;
      # 該当するCソースの内容があった場合
      if ($lineTemp){
       # 該当するCソースに改行コードを文字列「CR_LF_SPLITSTRING」に置換する
       $lineTemp =~ s/¥r|¥r¥n|¥n|¥cJ|¥cM/CR_LF_SPLITSTRING/g;
       $lineTemp =~ s/¥cI/ /g;
       # 文字列「CR_LF_SPLITSTRING」によって、行ごとにソースを配列@linesに格納する
       @lineTemps = split /CR_LF_SPLITSTRING/ , $lineTemp;
      }

      my $lineNum = 0;
      my $matchFileContents = "";
      foreach my $splitLine (@lineTemps) {
        $lineNum++;
        $matchFileContents .= " _LINE_".$lineNum."_LINE_ " . $splitLine;
      }

      my $matchContents;
      my $convertContents;
      while ($matchFileContents =~ / _LINE_(¥d+)_LINE_ ¥s*#¥s*if¥s*(¥d)([^#]*)(#¥s*else([^#]*))?#¥s*endif/){
        $matchContents = $&;
        my $convertLineNum = $1;
        $convertContents = ($2 == 1)?$3:($5)?$5:"";

        $matchContents =~ s/¥"/""/g;
        $convertContents =~ s/¥"/""/g;

        $matchContents =~ s/ _LINE_(¥d+)_LINE_ /¥n/g;
        $convertContents =~ s/ _LINE_(¥d+)_LINE_ /¥n/g;

        print DELETE_IF0_LIST_CSV_FILE_PATH "¥"$file¥",¥"$convertLineNum¥",¥"$matchContents¥",¥"$convertContents¥"¥n";
        $matchFileContents =~ s|#¥s*if¥s*(¥d)([^#]*)(#¥s*else([^#]*))?#¥s*endif|($1 == 1)?$2:($4)?$4:""|ems;
      }

      if ($matchContents){
        eval{
          my $convertFilePath = "";
          if ($file =~ /¥Q$SEARCH_TARGET_SOURCE_PATH¥E(.*?)$/){
            $convertFilePath = $OUTPUT_PATH . basename($SEARCH_TARGET_SOURCE_PATH) .'¥¥' . $1;
          }
          my $convertFolderPath = dirname($convertFilePath);
          unless ( -e $convertFolderPath ) {
            #mkdir("$convertFolderPath");
            mkpath($convertFolderPath,0,0755);
          }

          # 呼び出さないCメソッド情報一覧CSVファイルを開く
          open CONVERTED_FILE_PATH,">$convertFilePath" or
          die "Cannot open $convertFilePath: $!";

        };
        if($@){
          &logout("ERROR","ファイルの読み書きに例外が発生しました。【Method：DeleteIf0 詳細：$@】", __LINE__);
          die "ファイルの読み書きに例外が発生しました。【Method：DeleteIf0 詳細：$@】";
        }
        $matchFileContents =~ s/^ _LINE_(¥d+)_LINE_ //;
        $matchFileContents =~ s/ _LINE_(¥d+)_LINE_ /¥n/g;
        print CONVERTED_FILE_PATH $matchFileContents;
        close CONVERTED_FILE_PATH;
      }

    };
    if ($@) {
      #ログファイルに出力する
      &logout("ERROR","ファイルの読み込みに例外が発生しました。【Method：DeleteIf0 詳細：$@】", __LINE__);
      next;
    }
  }
}

#*************************************************************
#Function Name:logopen()
#Description:ログファイルを開く
#*************************************************************
sub logopen() {
  my $logFile = "$RESOURCES_DIR¥¥DELETEIF0.log";
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
  my $currentSourceName = "DeleteIf0.pl";

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
