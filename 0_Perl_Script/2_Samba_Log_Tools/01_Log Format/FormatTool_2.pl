#!/usr/bin/perl -w
#********************************************************************************************************
#FileName:LogMsgFormatTool.pl
#Description:Samba出力ログメッセージをフォーマットするツール
#1m ->4000
#********************************************************************************************************

use strict;
use warnings;
#use Data::Dumper;
#use File::Basename;
#use Encode;

# 本ツールの格納箇所
#my $RESOURCES_DIR = dirname(__FILE__);

# 出力されたフォーマット結果ファイルの格納箇所
my $RESULT_FILE = "Samba_Log_Format_Result.csv";
my $logFilePath = "";


#処理対象ファイル
my $Input_File = "";

#時間変数
my $year;
my $mon;
my $mday;
my $hour;
my $min;
my $sec;


#パラメータを取得する
if(@ARGV == 1){
  $Input_File = shift;

}else{
    die "【パラメータエラー】";
}

print "#####Program Start#####\n";

#logファイルを開く
&logopen();
&logout( "INFO", "Program START.", __LINE__ );
unless ( -e $Input_File ) {
  &logout("ERROR","処理対象ファイルが存在していません。【Method：Main 詳細：$Input_File】", __LINE__);
  die "処理対象ファイルが存在していません。【Method：Main 詳細：$Input_File】";
}

# ログファイルを読み込み、フォーマット処理を行う
&LogMsgFormat();

&logout( "INFO", "Program END.", __LINE__ );

&logclose();
print "\n#####Program  End#####\n";
print "$logFilePath\n";
print "Result file: \n  $RESULT_FILE\n\n";

#**********************************************************************************************
#Function Name:LogMsgFormat()
#Description:ログファイルを読み込み、フォーマットして、出力します。
#**********************************************************************************************
sub LogMsgFormat() {

    #変数一覧
    my $num = 0;            #ログファイルの現在行番号
    my $line = "";          #ログファイルの現在行の内容
    my $log_time = "";      #ログ出力の時間
    my $log_level = "";     #ログ出力のレベル
    my $log_pid = "";       #出力ログのPID
    my $log_other = "";     #[]に時間、PID以外の内容
    my $log_file = "";      #出力ログのファイル名
    my $log_lineNum = "";   #出力ログの行番号
    my $log_fun = "";       #出力ログの関数名
    my $log_msg = "";       #ログ内容

    
    #処理対象ファイルオープン
    eval{
      #ログファイルを開く
      open IN,"<$Input_File" or die "Cannot open $Input_File: $!";
    };
    if($@){
      &logout("ERROR","ファイルオープン例外が発生しました。【Method：LogMsgFormat 詳細：$@】", __LINE__);
      die "ファイルオープン例外が発生しました。【Method：LogMsgFormat 詳細：$@】";
    }
    
    #出力結果ファイルを開く
    eval{
      open OUT,">$RESULT_FILE" or die "Cannot open $RESULT_FILE: $!";
      printf (OUT "Time,Level,PID,Other,Source,Line,Function,Message");

    };
    if($@){
      &logout("ERROR","結果ファイルの読み書きに例外が発生しました。【Method：LogMsgFormat 詳細：$@】", __LINE__);
      die "結果ファイルの読み書きに例外が発生しました。【Method：LogMsgFormat 詳細：$@】";
    }
    

    
    #行単位で読み処理始め
    while($line = <IN>){
        $num++;
       
        print "\r第$num行フォーマット";
        #時間、PID、ファイル、行番号、関数名を取得する
        if($line =~ /\[(\d{4}\/\d{1,2}\/\d{1,2}\s+\d{2}\:\d{2}\:\d{2}\.\d{6}),\s+(\d+)(.*?)\]/){

            $log_time  = $1;
            $log_level = $2;
            #PIDを取得する
            if($3 =~ /[pid=](\d+)\,(.*)/){
                $log_pid   = $1;
                $log_other = $2;
            }else{
                $log_pid   = "";
                $log_other = "";
            }
            #ファイル、行番号、関数名を取得する
            my $str_file_line_fun = (split /\]\s+/ , $line)[-1];
            ($log_file,$log_lineNum,$log_fun) = split /\:|\(|\)/ , $str_file_line_fun;

            eval{
                    printf (OUT "\n\"\'%s\",%s,%s,\"%s\",\"%s\",%s,%s",$log_time,$log_level,$log_pid, $log_other,$log_file,$log_lineNum, $log_fun);
                    &logout("DEBUG","フォーマット始め:行番号$num", __LINE__);
                };
                if($@){
                    &logout("ERROR","第$num行フォーマット始め失敗！", __LINE__);
                    die "第$num行フォーマット始め失敗！詳細：$@";
                }

        }elsif($line =~ /^\s{2}/){

            #先頭または後ろのスペース・テーブルを除く
            $log_msg = trim($line);

            #出力処理
            eval{
                    printf (OUT "\,\"\%s\"",$log_msg);
                    &logout("DEBUG","第$num行書き込み", __LINE__);
                };
                if($@){
                    &logout("ERROR","第$num行書き込み失敗！", __LINE__);
                    die "第$num行書き込み失敗！詳細：$@";
                }

 
        }

    }#行単位で読み処理終了

    #ファイルクローズ
    close IN;
    close OUT;
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

  my $logFile = "MSG_FORMAT_$out_time.runlog";
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
#Parameters:ログ分類(D,I,E,W)、出力するログメッセージ、行目
#*************************************************************
sub logout(@) {
  # パラメータを取得する
  my ( $logType, $logMsg, $line ) = @_;

  my $str_time;
  
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
  #$logMsg = encode("UTF-8", decode("shiftjis",$logMsg) );
  #$logMsg = Encode::decode("utf-8",$logMsg);
  # ログファイル追加モードでオープン
  printf( LOG_FILE "%s %03d [%-7s]  %s\n",
    $str_time, $line, uc($logType), $logMsg );
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

