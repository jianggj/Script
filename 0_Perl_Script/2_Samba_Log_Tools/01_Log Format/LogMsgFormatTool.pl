#!/usr/bin/perl -w
#********************************************************************************************************
#FileName:LogMsgFormatTool.pl
#Description:Samba出力ログメッセージをフォーマットするツール
#1m ->4000
#********************************************************************************************************

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Next;
use Encode;

# 本ツールの格納箇所
#my $RESOURCES_DIR = dirname(__FILE__);

# 出力されたフォーマット結果ファイルの格納箇所
my $RESULT_FILE = "Samba_Log_Format_Result.csv";
my $logFilePath = "";

#ログメッセージ一覧ファイルに存在しないの情報を格納箇所
my $MSG_NOT_IN_LIST = "MessageNotInList.csv";

#処理対象ファイル
my $Input_File = "";
my $Msg_List_File = "";

#時間変数
my $year;
my $mon;
my $mday;
my $hour;
my $min;
my $sec;

#検索したのログメッセージを関連する情報を格納
my %hMsgList;

#パラメータを取得する
if(@ARGV == 2){
  $Input_File = shift;
  $Msg_List_File = shift;
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
unless ( -e $Msg_List_File ) {
  &logout("ERROR","ログメッセージファイルが存在していません。【Method：Main 詳細：$Msg_List_File】", __LINE__);
  die "ログメッセージファイルが存在していません。【Method：Main 詳細：$Msg_List_File】";
}

# ログファイルを読み込み、フォーマット処理を行う
&LogMsgFormat();

&logout( "INFO", "Program END.", __LINE__ );

&logclose();
print "#####Program  End#####\n";
print "$logFilePath\n";
print "Result file: \n  $RESULT_FILE\n\n";

#**********************************************************************************************
#Function Name:LogMsgFormat()
#Description:ログファイルを読み込み、フォーマットして、出力します。
#**********************************************************************************************
sub LogMsgFormat() {
    
    #変数一覧
    my $num = 0;            #ログファイルの現在行番号
    my $start_count = 0;    #時間存在の行数を統計
    my $line = "";          #ログファイルの現在行の内容
    my $log_time = "";      #ログ出力の時間
    my $log_level = "";     #ログ出力のレベル
    my $log_pid = "";       #出力ログのPID
    my $log_other = "";     #[]に時間、PID以外の内容
    my $log_file = "";      #出力ログのファイル名
    my $log_lineNum = "";   #出力ログの行番号
    my $log_fun = "";       #出力ログの関数名
    my $log_msg = "";       #ログ内容
    my %hNoMatchTime;       #マッチングしないの時間等を格納：KEY→時間；Value→時間レベルPID等
    my %hMatchTime;         #時間とマッチングできるのログメッセージを格納：KEY→時間；Value→ログメッセージ;
    my @NoMatchList;        #マッチングしないの時間リスト
#    my $msg_end_flag = 0;   #複数行ログメッセージ終了flag:0⇒ログ終了；1⇒ログ未終了・開始
    my $msg_check = "";     #ログメッセージファイルに取得したログメッセージ
    my %hERROR_MSG_LIST;    #ログメッセージファイルに存在しないの関数を関連する内容を格納
    my %hTimeLineNum;       #時間存在の行の番号を格納
    my %hToDelete;          #格納リスト削除用のマッチ完了のデータを格納
    my %hExceptionList;     #長いメッセージ例外リスト
    
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
      printf (OUT "Time,Level,PID,Other,Source,Line,Function,Message\n");

    };
    if($@){
      &logout("ERROR","結果ファイルの読み書きに例外が発生しました。【Method：LogMsgFormat 詳細：$@】", __LINE__);
      die "結果ファイルの読み書きに例外が発生しました。【Method：LogMsgFormat 詳細：$@】";
    }
    
    #ログメッセージ一覧ファイルに存在しないの情報格納ファイルを開く
    eval{
      open NOTINLIST,">$MSG_NOT_IN_LIST" or die "Cannot open $MSG_NOT_IN_LIST: $!";
      printf (NOTINLIST "Num,Time,File,Line,Function\n");
    };
    if($@){
      &logout("ERROR","メッセージ一覧に存在しないの情報格納ファイルの読み書きに例外が発生しました。【詳細：$@】", __LINE__);
      die "メッセージ一覧に存在しないの情報格納ファイルの読み書きに例外が発生しました。【Method：LogMsgFormat 詳細：$@】";
    }
    
    #行単位で読み処理始め
    while($line = <IN>){
        $num++;
        
        if($line =~ /^(\s{4})+/){
            &logout("DEBUG","第$num行が長い情報の一部です！", __LINE__);
            next;
        }
        
        #時間、PID、ファイル、行番号、関数名を取得する
        if($line =~ /\[(\d{4}\/\d{1,2}\/\d{1,2}\s+\d{2}\:\d{2}\:\d{2}\.\d{6}),\s+(\d+)(.*?)\]/){
            $start_count++;
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
            my $str_tlpf = $log_time."_JOIN_"
                          .$log_level."_JOIN_"
                          .$log_pid."_JOIN_"
                          .$log_other."_JOIN_"
                          .$log_file."_JOIN_"
                          .$log_lineNum."_JOIN_"
                          .$log_fun;
            if(exists $hNoMatchTime{$log_time}){#出力時間は同じ場合
                $log_time .="_SAME_TIME_";
            }
            $hNoMatchTime{$log_time} = $str_tlpf;
            push (@NoMatchList,$log_time);
#            $msg_end_flag = 1;
            
            $hTimeLineNum{$log_time} = $num ;
            print "第$num行読み、時間、PID、ファイル、行番号、関数名を取得...\n";
            &logout("DEBUG","第$num行処理開始、時間、PID、ファイル、行番号、関数名を取得\n", __LINE__);
            
            #既知のメッセージを取得
            if(exists $hExceptionList{$log_file}{$log_lineNum}{$log_fun}){
                 $hMatchTime{$log_time} = $hExceptionList{$log_file}{$log_lineNum}{$log_fun};
                 next;
            }
            unless (exists $hMsgList{$log_file}{$log_lineNum}{$log_fun}){
                #ログメッセージ一覧ファイルに検索
                $log_file =~ s/\.\.\///go;
                my $msg_tmp = &SearchMsgListFile($log_file,$log_lineNum,$log_fun);
                if($msg_tmp eq "" ){
                    &logout("ERROR",
                      "このメッセージが出力ログ一覧ファイルに存在しません。【ファイル名：$log_file,行番号：$log_lineNum,関数名：$log_fun】",
                       __LINE__);
#                    $hERROR_MSG_LIST{$log_file}{$log_lineNum}{$log_fun} = 1;
                    unless (exists $hERROR_MSG_LIST{$log_file}{$log_lineNum}{$log_fun}){
                        $hERROR_MSG_LIST{$log_file}{$log_lineNum}{$log_fun} = 1;
                        printf(NOTINLIST "%s,\`%s,%s,%s,%s\n",$num,$log_time,$log_file,$log_lineNum,$log_fun);
                    }
                    $hMatchTime{$log_time} = "";
                    $hExceptionList{$log_file}{$log_lineNum}{$log_fun} = $hMatchTime{$log_time};
                    #####?
                    next;
                }elsif($msg_tmp =~/_LONG_OUT_MSG_FLAG_JNOSS_/){
                    &logout("DEBUG","長いメッセージを出力したい！【行番号：$num】", __LINE__);
                    $hMatchTime{$log_time} = "※長いDEBUGメッセージを出力します※";
                    $hExceptionList{$log_file}{$log_lineNum}{$log_fun} = $hMatchTime{$log_time};
                    next;
                }
                $msg_tmp =~ s/\\n//g;
                $msg_tmp =~s/\n$//g;
                $hMsgList{$log_file}{$log_lineNum}{$log_fun} = $msg_tmp;
            }
            
#        }elsif(($line =~ /^\s{2}/)&&($msg_end_flag ==1)){
        }elsif($line =~ /^\s{2}/){
            
            #長い情報関連のメッセージをスキップ
            if($line =~ /^\s{2}\[[0-9A-Z]{4}\]( [0-9A-Z]{2})+/){
                &logout("DEBUG","第$num行が長い情報の一部です！", __LINE__);
                next;
            }
            
            #先頭または後ろのスペース・テーブルを除く
            $log_msg = trim($line);
            next if $log_msg =~ /^(\n|\t*|\s*|\h*)$/g;
            next if $log_msg eq "";
            
            print "第$num行読み、該当メッセージチェックを行う...\n";
            &logout("DEBUG","第$num行処理開始、メッセージチェックを行う\n", __LINE__);
            
            #該当メッセージと時間をマッチして、チェックを行う
            my $match_flag = 0;
            foreach my $key_time (@NoMatchList){
                
                next if exists $hMatchTime{$key_time};
                my $str_time_all= $hNoMatchTime{$key_time};
                my @arr_time_all= split /_JOIN_/ , $str_time_all;
                my $file_name = $arr_time_all[4];
                $file_name =~ s/\.\.\///go;
                next if exists $hERROR_MSG_LIST{$file_name}{$arr_time_all[5]}{$arr_time_all[6]};
                $msg_check = $hMsgList{$file_name}{$arr_time_all[5]}{$arr_time_all[6]};
                $msg_check =~ s/\n$//g;
#                $msg_check=~ s/(\%s|\%d|\%u)|\W/_CUT_FLAG_/g;
                $msg_check=~ s/(\%((\d+\.)?\d+)?(s|d|u|lu|f|x|X|lx|llx|hX|p))|\W/_CUT_FLAG_/g;
                $msg_check=~ s/(_CUT_FLAG_)+/_CUT_FLAG_/g;
                my @msg_check_cut;
                my $pt_now;
                my $str_log_msg;
                @msg_check_cut = split /_CUT_FLAG_/, $msg_check;
                $str_log_msg = $log_msg;
                foreach my $msg_check_cuts (@msg_check_cut){
                    next if $msg_check_cuts eq "";
                    if($str_log_msg =~ m/\Q$msg_check_cuts\E/g){
                        $pt_now = pos($str_log_msg);
                        $match_flag = 1;
                    }else{
                        $match_flag = 2;
                        last;
                    }
                    $str_log_msg = substr($str_log_msg,$pt_now);
                }
                undef(@msg_check_cut);
                #マッチの場合
                if ($match_flag == 1){
                    $hMatchTime{$key_time} = $log_msg;#メッセージ出力順と時間出力順違い場合、例外防止
                    last;
                }
            }
            my $length_List = @NoMatchList;
            unless($match_flag == 1){
                
                if($length_List == 0){
                	&logout("WARNING","第$num行メッセージが複数行メッセージの可能である！【メッセージ：$log_msg】", __LINE__);
                	print "【WARNING:$match_flag】第$num行メッセージが複数行メッセージの可能である！\n";
                }else{
                	&logout("ERROR","第$num行メッセージと時間マージ失敗($match_flag)！【メッセージ：$log_msg】", __LINE__);
                	print "【ERROR:$match_flag】第$num行メッセージと時間マージ失敗！\n";
                }
            }
            
            #フォーマット後のメッセージを出力
#            next unless (exists $hMatchTime{$NoMatchList[0]});
            if($length_List <100){ 
                #TODO:複数行ログ出力場合の処理
                next if $length_List == 0;
                next unless exists $hMatchTime{$NoMatchList[0]};
            }else{
                unless (exists $hMatchTime{$NoMatchList[0]}){
                    $hMatchTime{$NoMatchList[0]} = "";
                    &logout("WARNING","リストが制限の長さを超えたので、マージしない時間を出力します！【時間：$NoMatchList[0]】", __LINE__);
                    print "【WARNING】リストが制限の長さを超えたので、マージしない時間を出力します！\n";
                }
            }
            #出力処理
#            foreach my $time_tmp(@NoMatchList){
            foreach (@NoMatchList){
                #ループ制御
                my $length_tmp = @NoMatchList;
                last if $length_tmp == 0;
                my $time_tmp = $NoMatchList[0];
                last unless exists $hMatchTime{$time_tmp};
                #メッセージを出力:TIME	LEVEL	PID	Other	source	line	fun	msg
                my $time_out = $time_tmp;
                my $msg_out = $hMatchTime{$time_tmp};
                my $str_tmp = $hNoMatchTime{$time_out};
                my @str_out_tmp = split /_JOIN_/ , $str_tmp;
                my $time_out_check = $str_out_tmp[0];
                if ($time_out =~/_SAME_TIME_/){#出力時間は同じ場合、追加フラグを削除
                    $time_out =~s/_SAME_TIME_//g;
                }
                if($time_out_check ne $time_out){
                    &logout("ERROR","第$num行出力時、時間チェック失敗！【$time_out_check：$time_out】", __LINE__);
                    print "【ERROR】第$num行出力時、時間チェック失敗！\n";
                }
                my $leve_out = $str_out_tmp[1];
                my $pid_out = $str_out_tmp[2];
                my $other_out = $str_out_tmp[3];
                my $source_out =$str_out_tmp[4];
                my $line_out = $str_out_tmp[5];
                my $fun_out = $str_out_tmp[6];
                eval{
                    printf (OUT "\"\`%s\",%s,%s,\"%s\",\"%s\",%s,%s,\"%s\"\n",$time_out,$leve_out,$pid_out, $other_out,$source_out,$line_out, $fun_out,$msg_out);
                    &logout("DEBUG","フォーマット完了(時間の行番号$hTimeLineNum{$time_out})、結果ファイルに書き込む", __LINE__);
                };
                if($@){
                    &logout("ERROR","第$num行フォーマット結果書き込み失敗！", __LINE__);
                    die "第$num行フォーマット結果書き込み失敗！詳細：$@";
                }else{
                    #マッチ完了のデータをリストに削除
                    print "処理完了、結果ファイルに書き込む！\n\n";
                    delete $hMatchTime{$time_tmp};
                    delete $hToDelete{$time_tmp};
                    shift @NoMatchList;
                    redo;
                }
            }
        }else{
            
            &logout("WARNING","第$num行メッセージは処理できません！", __LINE__);
        }
    }#行単位で読み処理終了
    &logout("INFO","【時間存在の行数：$start_count】", __LINE__);
    #ファイルクローズ
    close IN;
    close OUT;
    close NOTINLIST;
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

#*************************************************************
#Function Name:SearchMsgListFile()
#Description:ログ一覧ファイルに検索
#*************************************************************
sub SearchMsgListFile(@) {
    my ( $file, $lineNum, $fun ) = @_;
    my $result_str = "";
    open MSGLIST ,"$Msg_List_File" or die "Can't open '$Msg_List_File': $!";
    while(my $line_tmp = <MSGLIST>){
        my @lines = split /\t/ , $line_tmp;
        my ($file_tmp, $lineNum_tmp,$fun_tmp) = split /\:|\(|\)/ ,$lines[0];
        if(($lineNum_tmp == $lineNum)&&($fun_tmp =~/\Q$fun\E/g)&&($file_tmp =~ /\Q$file\E/g)){
            $result_str = $lines[1];
            last;
        }
    }
    close MSGLIST;
    return $result_str;
}


