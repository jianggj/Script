#!/usr/bin/perl -w
######################################################################
#FileName:All.pl
#Description:指定されたファイルに対して、LDAPログ（256）を解析する。
######################################################################

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use Encode;
use File::Path;
use Time::Local;

#===========変数定義 Start===========
my $linetest=0;
# 本ツールの格納箇所
my $TOOL_DIR = dirname(__FILE__);
# ファイルの格納箇所パス（ファイル名）
my $LOG_FILE;
#時間（ファイル名）
my $year;
my $mon;
my $mday;
my $hour;
my $min;
my $sec;
##########################
#指定する時間（秒）、この時間によりも大きいOPを出力、修正可
#デフォルトは1秒です、1秒以上のOPを出力
my $set_time_range=1;
##########################

#エントリOPの時間統計
my $op_time=0;
my %hTime_out;
my $timeout_count=0;
my %hTimeout_op;
#格納HASH
my %hConns;
my %hConn_ops; #各接続の内容

#ァイルを読み込み用
my @lines;

#接続CLASS
my %hConnClass;
#%hConnClass：
#%hConnClass{$conn no}=(
#     {"OP_NO"} => "0|1|...|9999";  op数
#     {$op no}=>(                         OPのhash
#                             {"OP_Start"} => op開始時間
#                              {"OP_End"} => op終了時間
#                              {"OP_Time"}
#                                  );
#);

#月変換
my %hMonth=(
"Jan" => 0, "Feb" => 1, "Mar" => 2,
"Apr" => 3, "May" =>4, "Jun" => 5,
"Jul" => 6, "Aug" => 7, "Sep" => 8,
"Oct" => 9, "Nov" => 10, "Dec" => 11
);
#===========変数定義 END===========

#------------------------------前処理 --------------------------------

print "==========Programe START! ==========\n";

#パラメータ(解析ログの格納箇所)を取得する
if(@ARGV == 1)
{
	$LOG_FILE = shift;
}elsif(@ARGV == 0){
	die "ログファイルをご指定ください！\n**********Programe EXIT**********\n";
}else{
	die "ログファイル指定エラー！\n*Programe EXIT*\n";
}
unless ( -e $LOG_FILE ) 
{
	#printf( OUT_FILE "ログファイル[%s]が存在していません！\n*Programe EXIT*\n",$LOG_FILE);
	die "ログファイルが存在していません。\n**********Programe EXIT**********\n";
}

#結果出力ファイルを開く
&outputopen();
print "ログファイル:$LOG_FILE\n";
printf(OUT_FILE "ログファイル:%s\n",$LOG_FILE); 

#------------------------------主処理 --------------------------------
#ログファイルを読み込み
eval {
  # 該当ログファイルを開く
  open IN, "$LOG_FILE" or die "Can't open '$LOG_FILE': $!\n";
  # 該当するログの内容を$lineに格納する
  print "ファイル読み込み中。。。\n";
  my $line = do { local $/; <IN> };
  close IN;
  print "ファイル読み込み完了\n";
  # 該当するログの内容があった場合
  if ($line)
  {
        # 該当するソースに改行コードを文字列「¶CR_LF_SPLITSTRING¶」に置換する
        $line =~ s/\r|\r\n|\n|\cJ|\cM/CR_LF_SPLITSTRING/g;
        $line =~ s/\cI/ /g;
        # 文字列「CR_LF_SPLITSTRING」によって、行ごとにソースを配列@linesに格納する
        @lines = split /CR_LF_SPLITSTRING/ , $line;
   }
};
if ($@)
{
  #読み込みに例外が発生の場合、処理中止
  #printf(OUT_FILE "ファイル読み込み例外発生:%s\n*Programe EXIT*\n",$@);
  die "【ERROR】:ファイル[$LOG_FILE]読み込み例外発生！\n詳細：$@\n";
}
{
	#ログ開始日時取得
	my $firstline=$lines[1];
	my @firstlines=split /\s+/ , $firstline;
	my ($smon,$sday,$stime)=@firstlines[0,1,2];
	my $StartTime=$smon." ".$sday." ".$stime;
	#print "ログ開始日時 ：".$StartTime."\n";

	#ログ終了日時取得
	my $lastline=$lines[-1];
	my @lastlines=split /\s+/ , $lastline;
	my ($fmon,$fday,$ftime)=@lastlines[0,1,2];
	my $FinishTime=$fmon." ".$fday." ".$ftime;
	#print "ログ終了日時 ：".$FinishTime."\n";
	
	printf(OUT_FILE "\n%s 〜 %s\n",$StartTime,$FinishTime);
}
#行処理開始
print "処理中。。。\n";

foreach my $splitLine (@lines)
{	
	my $con_code;  #接続番号
	my $op_code; #OP番号
	my $op;
	#ログレベルは「-1」の場合、無用ログを処理しない
    if($splitLine =~/.*?daemon\:.*/i)
    {
		next;
	}
    #接続番号取得
	if($splitLine =~ /(?:.*)conn=(\d+)(?:.*)/i)
	{
	    $con_code =$1;
	    $hConns{$con_code}=1;
	    my $op_code_tmp="";
	    #$hConnClass{$con_code}{"OP_NO"} = "";
	    #接続時間を取得
	    {
			my @line_time=split /\s+/ , $splitLine;
			my $op_year=( localtime(time) )[ 5 ];
			my ($op_mon,$op_day,$op_hhmmss)=@line_time[0,1,2];
			my ($op_hour,$op_min,$op_sec)=split/\:/,$op_hhmmss;
			#print $op_year,"-",$op_mon,"-",$op_day,"-",$op_hour,"-",$op_min,"-",$op_sec,"\n";
			$op_time=timelocal($op_sec,$op_min,$op_hour,$op_day,$hMonth{$op_mon},$op_year);
		}
	    
	    #接続により、内容を保存
	    if($splitLine =~/\bop=(\d+) (\S+).*/i)
	    {
			$op_code_tmp=$1."";
		}else{
			$op_code_tmp="-1";
		}
	    $hConn_ops{$con_code}{$op_code_tmp} .= $splitLine."\n";

	}else{
		#接続番号取得できない及び重大なエラーのキーと一致しない場合
		next;
	}
	
	next if ($splitLine =~ /(.*)ACCEPT(.*)/i );
	next if ($splitLine =~ /(.*)fd=(\d+)(\s*)closed(.*)/i);

	
	#OP取得
	if($splitLine =~/\bop=(\d+) (\S+).*/i)
	{
		$op_code=$1;
		$op=$2;
		#$hConnClass{$con_code}{"OP_NO"} = "";
		#OPがRESULTの場合、該当接続のOPRフラグを設定
		#該当接続のOP数を追加
		if(!exists $hConnClass{$con_code}{"OP_NO"}||$hConnClass{$con_code}{"OP_NO"} eq "")
		{
			$hConnClass{$con_code}{"OP_NO"} ="".$op_code;
		}else{
			unless($hConnClass{$con_code}{"OP_NO"} =~ /\b$op_code\b/i)
			{
				$hConnClass{$con_code}{"OP_NO"} .="|".$op_code;
			}
		}
		#該当接続のclassを設定
		$hConnClass{$con_code}{$op_code}{"OP"} =$op;
		$hConnClass{$con_code}{$op_code}{"OPR"} = 0;
			
		unless(exists $hConnClass{$con_code}{$op_code}{"OP_Start"})
		{
			$hConnClass{$con_code}{$op_code}{"OP_Start"}=$hConnClass{$con_code}{$op_code}{"OP_End"}=$op_time;
			$hConnClass{$con_code}{$op_code}{"OP_Time"}=$hConnClass{$con_code}{$op_code}{"OP_End"}-$hConnClass{$con_code}{$op_code}{"OP_Start"};
		}else
		{
			if($op_time < $hConnClass{$con_code}{$op_code}{"OP_Start"})
			{
				$hConnClass{$con_code}{$op_code}{"OP_Start"}=$op_time;
			}elsif($op_time > $hConnClass{$con_code}{$op_code}{"OP_End"})
			{
				$hConnClass{$con_code}{$op_code}{"OP_End"}=$op_time;
			}
			$hConnClass{$con_code}{$op_code}{"OP_Time"}=$hConnClass{$con_code}{$op_code}{"OP_End"}-$hConnClass{$con_code}{$op_code}{"OP_Start"};
		}
    #print $op_time,"\t",$hConnClass{$con_code}{$op_code}{"OP_Start"},"\t",$hConnClass{$con_code}{$op_code}{"OP_End"},"\t",$hConnClass{$con_code}{$op_code}{"OP_Time"},"\n";
	}
}#行処理終了

foreach my $con(sort{$a<=>$b} keys %hConns)
{
	#OP番号存在しない場合（ACCEPTとCLOSE）
	next unless exists $hConnClass{$con}{"OP_NO"};
	
	my $op_no=$hConnClass{$con}{"OP_NO"};
	my @ops= split /\|/ , $op_no;
	foreach my $opc (@ops)
	{
		my $op = $hConnClass{$con}{$opc}{"OP"}; 

		#時間が2秒以上の場合
		if($hConnClass{$con}{$opc}{"OP_Time"}>$set_time_range)
		{
			$hTime_out{$con}{$opc}=1;
			$timeout_count++;
			$hTimeout_op{$hConnClass{$con}{$opc}{"OP_Time"}}=1;
		}
	}
}
#------------------------------後処理 --------------------------------

printf(OUT_FILE "\n%s%s%s\n","="x34,"統計結果一覧","="x34);
{
	printf(OUT_FILE "同一OPの実行時間が指定された時間（%d秒）より多いの数：%d\n",$set_time_range,$timeout_count);
	printf(OUT_FILE "実行時間の一覧：\n");
	my $c_tmp=0;
	foreach my $sec_tmp(sort{$a<=>$b} keys %hTimeout_op)
	{
		$c_tmp++;
		printf(OUT_FILE "%5d秒\t",$sec_tmp);
		printf(OUT_FILE "\n") if ($c_tmp %5== 0);
	}
}
printf(OUT_FILE "\n%s%s%s\n","="x34,"統計結果詳細","="x34);
{
	foreach my $c_code(sort{$a<=>$b} keys %hTime_out)
	{
		my %hOP_tmp = %{$hTime_out{$c_code}};
		foreach my $op_code (sort{$a<=>$b} keys %hOP_tmp)
		{
				printf(OUT_FILE "【実行時間：%d秒】\n",$hConnClass{$c_code}{$op_code}{"OP_Time"});
				printf(OUT_FILE "%s\n",$hConn_ops{$c_code}{$op_code});
		}
	}
}
#終了
printf(OUT_FILE "%s\n","="x80);
print "処理完了\n";
&outputclose();
print "==========Programe FINISH!==========\n";
#================関 数 ===============

#*************************************************************
#Function Name:outputopen()
#Description:ログファイルを開く
#*************************************************************
sub outputopen() {
	my $t_outFile;
	# 日、月、年、週のみを取得する
	# 秒、分、時のみを取得する
	( $sec, $min, $hour, $mday, $mon, $year) = ( localtime(time) )[ 0 .. 5 ];
	$year += 1900;
	$mon+= 1;
	my $str_time = sprintf( "%4d%02d%02d%02d%02d%02d",$year, $mon, $mday, $hour, $min, $sec);
	$t_outFile = "$TOOL_DIR/Result_$str_time.log";
	print "結果出力ファイル：\n  $t_outFile\n";
	open( OUT_FILE, ">>$t_outFile" );
}

#*************************************************************
#Function Name:outputclose()
#Description:ログファイルを閉める
#*************************************************************
sub outputclose() {
	close OUT_FILE;
}
