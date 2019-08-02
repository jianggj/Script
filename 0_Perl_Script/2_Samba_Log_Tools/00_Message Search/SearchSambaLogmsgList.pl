#!/usr/bin/perl -w
#********************************************************************************************************
#FileName:SearchSambaLogmsgList.pl
#Description:プロジェクトディレクトリの配下にSambaログメッセージ（Debug）を取得し、抽出するツール
#            使用：SearchSambaLogmsgList.pl /path/to/Samba/
#********************************************************************************************************

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Next;
use Encode;

# 本ツールの格納箇所
#my $RESOURCES_DIR = dirname(__FILE__);

# 出力された呼び出さないメソッド一覧の格納箇所
#my $SAMBA_LOGMSG_LIST_FILE="Samba_Logmsg_list.csv";
my $SAMBA_LOGMSG_LIST_FILE="Samba_Logmsg_list.xls";
my $logFilePath = "";

# 出力されたメソッド一覧CSVファイルの格納箇所
my $SEARCH_target_SOURCE_PATH = "";

# 正式表現式（関数の宣言をマッチする）
my $REGEXSTRING_FUNCTION_DECLARATION = "";

#時間変数
my $year;
my $mon;
my $mday;
my $hour;
my $min;
my $sec;

#パラメータを取得する
if(@ARGV == 1){
  $SEARCH_target_SOURCE_PATH = shift;
}

#パースパース末尾に\/がない場合\/を追加
unless ( $SEARCH_target_SOURCE_PATH =~ /\/$/ ) {
  $SEARCH_target_SOURCE_PATH = "$SEARCH_target_SOURCE_PATH\/";
}

print "#####Program Start#####\n";

#logファイルを開く
&logopen();
&logout( "INFO", "Program START.", __LINE__ );
unless ( -e $SEARCH_target_SOURCE_PATH ) {
  &logout("ERROR","解析先対象フォルダが存在していません。【Method：Main 詳細：$SEARCH_target_SOURCE_PATH】",
    __LINE__);
  die "解析先対象フォルダが存在していません。【Method：Main 詳細：$SEARCH_target_SOURCE_PATH】";
}

# プロジェクトディレクトリの配下にDEBUGログメッセージを取得して、抽出するツール
&SearchSambaLogmsgList();

&logout( "INFO", "Program END.", __LINE__ );

&logclose();
print "#####Program  End#####\n";
print "$logFilePath\n";
print "Result file: \n  $SAMBA_LOGMSG_LIST_FILE\n";

#**********************************************************************************************
#Function Name:SearchSambaLogmsgList()
#Description:プロジェクトディレクトリの配下にDEBUGログメッセージを取得して、抽出する
#**********************************************************************************************
sub SearchSambaLogmsgList() {

  my $line;
  my @lines;
  my $sourceContents;
  my %hFunctionToSource=();

  eval{
    #DEBUGログメッセージ一覧CSVファイルを開く
    open SAMBA_LOGMSG_LIST_FILE,">$SAMBA_LOGMSG_LIST_FILE" or 
    die "Cannot open $SAMBA_LOGMSG_LIST_FILE: $!";
  };
  if($@){
    &logout("ERROR","ファイルの読み書きに例外が発生しました。【Method：SearchSambaLogmsgList 詳細：$@】", __LINE__);
    die "ファイルの読み書きに例外が発生しました。【Method：SearchSambaLogmsgList 詳細：$@】";
  }

  # パラメーターに指定されたフォルダにすべてC言語のソースを検索する
  my $files = File::Next::files({file_filter =>\&c_file_filter,
  descend_filter => \&descend_filter}, $SEARCH_target_SOURCE_PATH);

  # 検索されたC言語のソースごとに、下記の処理を行う
  while ( defined( my $file = $files->() ) ) {
    unless ( -e $file ) {
      &logout("ERROR","該当するファイルが存在していません。【Method：SearchSambaLogmsgList 詳細：$file】", __LINE__);
      next;
    }

    print "Open the file: $file\n";

    &logout("DEBUG","METHOD名を取得。【ファイル名：$file】",__LINE__);
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
        $line =~ s/\r|\r\n|\n|\cJ|\cM/CR_LF_SPLITSTRING/g;
        $line =~ s/\cI/ /g;
        # 文字列「CR_LF_SPLITSTRING」によって、行ごとにソースを配列@linesに格納する
        @lines = split /CR_LF_SPLITSTRING/ , $line;
      }
      # C言語のソースのコメントを除いて、ソース本体を取得して、$sourceContentsに格納する
      $sourceContents = deleteCommentFromClanguageSource(\@lines);
    };
    if ($@) {
      #ログファイルに出力する
      &logout("ERROR","ファイルの読み込みに例外が発生しました。【Method：SearchSambaLogmsgList 詳細：$@】", __LINE__);
      next;
    }
  
    if ($file =~ /(\.c)$/){
#      $REGEXSTRING_FUNCTION_DECLARATION = '(((?:static\s+)?\w+(?:\*)*)\s+((?:\*)*\w+)\s*\(([^)]*)\)\s*\{)';
      $REGEXSTRING_FUNCTION_DECLARATION = '(((?:static\s+)?\w+(?:\*)*)\s+((?:\*)*\w+)\s*\(([^)]*)\)\s*)';
    }
  
    #ファイルにすべての関数名を取得する
    my $fun_name_str="";
    my $fun_names="";

    my $functioncutLine_FN = $sourceContents;
        while ( $functioncutLine_FN =~s/$REGEXSTRING_FUNCTION_DECLARATION\{/\{/) {
          my $functionName = trim($3);print  "$functionName\n";
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

          $fun_name_str =$1;
          if($fun_name_str =~ /(.*?\()/){
            $fun_name_str = $1;
            $fun_name_str =~s/(\(|\*)/\\$1/g;
          }
          if($fun_names){
            $fun_names .= "|".$fun_name_str;
          }else{
            $fun_names = $fun_name_str;
          }
        }
    #メソッド名取得完了
    
    #該当関数のソース保存
    my @function;
    my $line_fun_cut = $line;#print "$line_fun_cut\n";
    my $fun_names_tmp="(".$fun_names.")";
    $line_fun_cut =~s/$fun_names_tmp/__FUNCTION_NAME_FLAG__$1/g;
    my @line_fun_cuts = split /__FUNCTION_NAME_FLAG__/ , $line_fun_cut;
    foreach my $line_fun_cut_tmp (@line_fun_cuts){
        if($line_fun_cut_tmp =~ /\bDEBUG\b/g){
          my $FUNCTION_LINE_CUT = '((?:static\s+)?\w+)*\h+((?:\*)*\w+)\(.*?\{.*DEBUG(\(.*?\)\;)';
          if($line_fun_cut_tmp =~/$FUNCTION_LINE_CUT/){
            my $function_name_tmp = $2;
            #delete *
            if($function_name_tmp =~ /^\*(.*)/ ){
              $function_name_tmp = $1;
            }
            #TODO
#            if($function_name_tmp =~ m/CR_LF_SPLITSTRING/g){
#                #関数戻りタイプと名間に改行コードが存在する場合
#                my @fun_name_tmp = split /CR_LF_SPLITSTRING/ , $function_name_tmp;
#                $function_name_tmp = $fun_name_tmp[-1];
#            }
            next if exists $hFunctionToSource{$function_name_tmp};
            #関数名確認
            my @fun_name_verify =  split /CR_LF_SPLITSTRING/ , $line_fun_cut_tmp;
            if( ($fun_name_verify[0] =~ /\Q$function_name_tmp\E/g)|($fun_name_verify[1] =~ /\Q$function_name_tmp\E/g)){
                $hFunctionToSource{$function_name_tmp}=$line_fun_cut_tmp;
                push (@function,$function_name_tmp);
            }else{
                &logout("WARNING","関数名確認失敗！【ファイル：$file  関数：$function_name_tmp】",__LINE__);
            }
          }
        }
    }#関数のソース保存完了
    &logout("DEBUG","DEBUG出力を含むメソッド名を取得。【メソッド名：@function】",__LINE__);
    print "Get Method Name Finish\n";


    #各関数内、DEBUGの関連内容を確認
#    foreach my $function_name (keys %hFunctionToSource){#DEBUGがあるメソッドのHashの循環を行う
    foreach my $function_name (@function){
        my @point;
        my $count_CR = 0;
        my $msg = "";
        my $funcion_source = $hFunctionToSource{$function_name};
        if( !$funcion_source ){
            &logout("ERROR","ソースHashを取得できません！【$file($function_name)： $funcion_source 】",__LINE__);
            next;
        }

        #関数の始める行番号を取得
        my $function_lint_num;
        {
            my $resultNum = getFunctionLineNum($file,$function_name);
            $function_lint_num = $resultNum + 0;
            if(($function_lint_num =~ /\d+/)&($function_lint_num != 0)){
                &logout("DEBUG","関数開始の行番号を取得。【関数名：$function_name  開始の行番号：$function_lint_num】",__LINE__);
                print "Get the Line number...\n";
            }else{
                &logout("ERROR","関数開始の行番号を取得できません。【ファイル：$file  関数名：$function_name】",__LINE__);
                print "【ERROR】関数開始の行番号を取得できません。\n  ファイル：$file  関数:$function_name($function_lint_num)\n";
            }
        }

        #DEBUG始めのロケーションを取得
        while($funcion_source =~ m/\bDEBUG\b/g){
          
          my $pt = pos($funcion_source);
          #DEBUG関数以外の「DEBUG」文のロケーションを除く
          my $pt_end = index($funcion_source,');',$pt);
          next if $pt_end < 0 ;
          my $str = substr($funcion_source,$pt-5,$pt_end-$pt+7);
#          next unless $str =~ /\bDEBUG\((\w+|\d+).*?\)\;/g;
          next unless $str =~ /\bDEBUG\(((\s{0,1})\w|\d)+.*?\)\;/g;
          #DEBUGのロケーションを保存
          push (@point,$pt);
        }
        
        &logout("DEBUG","DEBUGのロケーションを取得。【ロケーション：@point】",__LINE__);

        #場所の数を取得
        my $pt_tmp = @point;
        if($pt_tmp == 1){#関数に、一つのDEBUGが出力する場合
            #関数の開始行から、DEBUG終了まで、ソースの行数を取得
            my $pt_end = index($funcion_source,');CR_LF_SPLITSTRING',$point[0]);
            my $str_tmp = substr($funcion_source,0,$pt_end+2);
            #改行コード数を取得
            $count_CR = ($str_tmp =~ s/CR_LF_SPLITSTRING/_CR_LF_SPLITSTRING_/g);
            
            #DEBUGのメッセージ取得
            my $debug_str = substr($funcion_source,$point[0]-5,$pt_end-$point[0]+7);
#            if($debug_str =~ /\bDEBUG\((\d+|\w+),.*?(\".*\")/g){
            if($debug_str =~ /\bDEBUG\((.*?),.*?((?:\".*?\"(?:CR_LF_SPLITSTRING|\s)*\,)|(?:\".*\"(\s)*\)))/g){
                $msg = $2;
                #メッセージの「"」と改行コードを除く
                $msg =~ s/CR_LF_SPLITSTRING|\s\\\s|(^\s+)|(\s+$)//g;
                $msg =~ s/(\"\s+(\\)*(\s*)\")/ /g;
                $msg =~ s/(\,|\))$//g;
                $msg =~ s/\t|(^\")|(\"$)//g;
                print "Get Log Message\n";
            }elsif($debug_str =~ /\bDEBUG\((\s)*\w+(\s)*\,(\s)*\((\s)*\w+(\s)*\)\)\;/g){
                $msg = "【メッセージはsprintf関数を使用して作成しますので、詳細内容がファイル($file)に関数($function_name)を参照します。】";
                &logout("WARNING","DEBUGのメッセージはsprintf関数が使用して作成します。",__LINE__);
            }else{
                &logout("ERROR","DEBUGのメッセージ取得できません。【ファイル：$file  関数:$function_name  DEBUGの場所:$point[0]】",__LINE__);
                print "【ERROR】DEBUGのメッセージ取得できません。\n  ファイル：$file  関数:$function_name  DEBUGの場所:$point[0]\n";
            }
            
            #結果を出力ファイルに書き込む
            my $lineNo  =$function_lint_num+$count_CR;
            printf(SAMBA_LOGMSG_LIST_FILE "%s:%s(%s)\t%s\n",$file,$lineNo,$function_name,$msg);
            &logout("INFO","結果をCSVファイルに書き込む",__LINE__);
            print "Write the message to CSV file... \n";

        }elsif($pt_tmp >1){#二つ以上のDEBUG出力場合
            #各DEBUG出力場所に対して、ソースの行数とMSGを取得
            foreach my $point_tmp (@point){
                $msg = "";
                $count_CR = 0;
                #DEBUG文終了ロケーションを取得
                my $pt_end_m = index($funcion_source,');CR_LF_SPLITSTRING',$point_tmp);
                my $str_tmp_m = substr($funcion_source,0,$pt_end_m+2);
                $count_CR = ($str_tmp_m =~ s/CR_LF_SPLITSTRING/_CR_LF_SPLITSTRING_/g);
                
                #DEBUGのメッセージ取得
                my $debug_str = substr($funcion_source,$point_tmp-5,$pt_end_m-$point_tmp+7);
#                if($debug_str =~ /\bDEBUG\((\d+|\w+),.*?(\".*\")/g){
                if($debug_str =~ /\bDEBUG\((.*?),.*?((?:\".*?\"(?:CR_LF_SPLITSTRING|\s)*\,)|(?:\".*\"(\s)*\)))/g){
                    $msg = $2;
                    #メッセージの「"」と改行コードを除く
                    $msg =~ s/CR_LF_SPLITSTRING|\s\\\s|(^\s+)|(\s+$)//g;
                    $msg =~ s/(\"\s+(\\)*(\s*)\")/ /g;
                    $msg =~ s/(\,|\))$//g;
                    $msg =~ s/\t|(^\")|(\"$)//g;
                    print "Get Log Message\n";
                }elsif($debug_str =~ /\bDEBUG\((\s)*\w+(\s)*\,(\s)*\((\s)*\w+(\s)*\)\)\;/g){
                    $msg = "【メッセージはsprintf関数使用して作成しますので、詳細内容がファイル($file)に関数($function_name)を参照します。】";
                    &logout("WARNING","DEBUGのメッセージはsprintf関数が使用して作成します。",__LINE__);
                }else{
                    &logout("ERROR","DEBUGのメッセージ取得できません。【ファイル：$file  関数:$function_name  DEBUGの場所:$point[0]】",__LINE__);
                    print "【ERROR】DEBUGのメッセージ取得できません。\n  ファイル：$file  関数:$function_name  DEBUGの場所:$point[0]\n";
                }
                
                #結果を出力ファイルに書き込む
                my $lineNo  =$function_lint_num+$count_CR;
                printf(SAMBA_LOGMSG_LIST_FILE "%s:%s(%s)\t%s\n",$file,$lineNo,$function_name,$msg);
                &logout("INFO","結果をCSVファイルに書き込む",__LINE__);
                print "Write the message to CSV file... \n";
            }#各DEBUG出力場所のソース行数とMSG取得完了
        }#二つ以上のDEBUG出力場合end
    }#DEBUGの関連内容を確認完了
    

  }#検索されたC言語のソースごとに、処理完了
#return;1;

  close SAMBA_LOGMSG_LIST_FILE;
  
  #一部変数のメモリ解放
  undef($line);
  undef(@lines);
  undef($sourceContents);
  undef(%hFunctionToSource);

}

#*************************************************************
#Function Name:logopen()
#Description:ログファイルを開く
#*************************************************************
sub logopen() {

  # 日、月、年、週のみを取得する
  ( $mday, $mon, $year ) = ( localtime(time) )[ 3 .. 5 ];
  # 秒、分、時のみを取得する
  ( $sec, $min, $hour ) = ( localtime(time) )[ 0 .. 2 ];
  $year += 1900;
  $mon  += 1;
  my $out_time = sprintf( "%4d-%02d-%02d-%02d%02d%02d",
              $year, $mon, $mday, $hour, $min, $sec);

  my $logFile = "SEARCH_SAMBA_LOGMSG_LIST_$out_time.log";
#  my $logFile = "\/var\/log\/SEARCH_SAMBA_LOGMSG_LIST_$out_time.log";
  $logFilePath =  sprintf("Log File :\n  %s",$logFile);
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

  my $str_time;
  
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
  $str_time = sprintf( "%4d-%02d-%02d %02d:%02d:%02d",
              $year, $mon, $mday, $hour, $min, $sec);
  $logMsg=~s/\n//;

  #エンコードはUTF-8に変更する
 # $logMsg = encode("UTF-8", decode("shiftjis",$logMsg) );
  #$logMsg = Encode::decode("utf-8",$logMsg);
  # ログファイル追加モードでオープン
  printf( LOG_FILE "%s %03d [%-7s]  %s\n",
    $str_time, $line, uc($logType), $logMsg );
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
  my $returnSting = 0;
  my @lines_tmp;
  my $fun_flag = 0;
  my $semicolon_flag = 0;
  
  # 該当するCソースを開く
  open IN, "$file" or die "Can't open '$file': $!";
  # 該当するCソースの内容を$lineに格納する
  my $line_tmp = do { local $/; <IN> };
  close IN;
  # 該当するCソースの内容があった場合
  if ($line_tmp){
   # 該当するCソースに改行コードを文字列「CR_LF_SPLITSTRING」に置換する
   $line_tmp =~ s/\r|\r\n|\n|\cJ|\cM/CR_LF_SPLITSTRING/g;
   $line_tmp =~ s/\cI/ /g;
   # 文字列「CR_LF_SPLITSTRING」によって、行ごとにソースを配列@linesに格納する
   @lines_tmp = split /CR_LF_SPLITSTRING/ , $line_tmp;
  }

  foreach my $splitLine (@lines_tmp) {
    $lineNum++;
    $_ = $splitLine;

    #改行コードを除く
    chomp;

    #行頭の空文字を除く
    #s/^\s+//g;
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

    if(/^ $/){
      next;
    }

    if(/(((static\s+)?\w+(\*)*)\s+((\*)*\Q$functionName\E)\s*\()/){
      $returnSting = $lineNum;
      next if /((\*)?\Q$functionName\E).*\)\s*\;/ ;
      $fun_flag = 1;
      $semicolon_flag = 0;
#      return $returnSting;
#    }elsif($beforeLine." ".$_ =~ /(((static\s+)?\w+(\*)?)\s+((\*)?\Q$functionName\E)\s*\()/){#関数の戻りタイプと名間に改行コードが存在する場合
#      $returnSting = $lineNum;
#      next if /((\*)?\Q$functionName\E).*\)\s*\;/ ;
#      return $returnSting;
    }
    if($fun_flag){
        return $returnSting if((/\{/)&&($semicolon_flag == 0));
        if(/\;|\)\;/){
        	$returnSting = 0;
            $fun_flag = 0;
            $semicolon_flag = 1;
            next;
        }
    }
  }
  undef(@lines_tmp);
  undef($line_tmp);
  return 0;
}

#*************************************************************
#Function Name:trim()
#Description:文字列に先頭または後ろのスペース・テーブルを除く
#*************************************************************
sub trim($) {
  my $string = shift;
  $string =~ s/^\s+// if defined($string);
  $string =~ s/\s+$// if defined($string);
  $string =~ s/^\t+// if defined($string);
  $string =~ s/\t+$// if defined($string);

  $string =~ s/\t+/ /g if defined($string);
  $string =~ s/\s+/ /g if defined($string);

  return $string;
}

#*************************************************************
#Function Name:c_file_filter()
#Description:Cソースのみを出力するフィルタ
#*************************************************************
sub c_file_filter { 
    # 呼び出し元：File::Next:files.
    # C言語のソースのみを出力するフィルタ
    /\.c$/
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
