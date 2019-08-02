#!/usr/bin/perl -w
######################################################################
#FileName:conn_op.pl
#Description:指定されたファイルに対して、LDAPログ（256）を解析する。
#            接続のOP数を統計
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

#格納HASH
my %hConns;
my %hConn_ops; #各接続開始op 終了op
#%hConn_ops{$conn no}=({"start_op"}=>val,{"end_op"}=>val,{"op"}=>{op1,op2,...})
my $Conn_count=0;

#ァイルを読み込み用
my @lines;

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
  die "【ERROR】:ファイル[$LOG_FILE]読み込み例外発生！\n詳細：$@\n";
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
		unless(exists $hConns{$con_code})
		{
	      $hConns{$con_code}=1;
	      $Conn_count++;
		
		}
		#OP取得
	    if($splitLine =~/\bop=(\d+) (\S+).*/i)
	    {
			$op_code=$1;
			unless(exists $hConn_ops{$con_code}{"start_op"})
        	{
        	  $hConn_ops{$con_code}{"start_op"} =  $op_code;
			  $hConn_ops{$con_code}{"end_op"} =  $op_code;
        	}else{
        	    
			  if($op_code >  $hConn_ops{$con_code}{"end_op"})
        	  {
        	    $hConn_ops{$con_code}{"end_op"} = $op_code;
        	  }
        	}

			unless(exists $hConn_ops{$con_code}{"op"}{$con_code})
			{
			  $hConn_ops{$con_code}{"op"}{$con_code} = 1;
			}
		}else{
		    next;	
		}

	}else{
		#接続番号取得できない及び重大なエラーのキーと一致しない場合
		next;
	}


}#行処理終了

#------------------------------後処理 --------------------------------
my $no_op_count=0;
foreach my $c_code (keys %hConns)
{
  unless(exists $hConn_ops{$c_code}{"start_op"})
  {
    $no_op_count++;
  }
}


printf(OUT_FILE "\n%s%s%s\n","="x34,"統計結果一覧","="x34);
{
	printf(OUT_FILE "接続数：%d\n",$Conn_count);
	print "すべての接続数：$Conn_count\n";
	printf(OUT_FILE "OP番号存在しない接続数：%d\n",$no_op_count);
}
printf(OUT_FILE "\n%s%s%s\n","="x34,"統計結果詳細","="x34);
{
  foreach my $c_code(sort{$a<=>$b} keys %hConns)
  {
    if(exists $hConn_ops{$c_code}{"start_op"}) 
	{
      printf(OUT_FILE "【接続番号：%d】開始OP番号：%6d   終了OP番号：%6d\n",$c_code,$hConn_ops{$c_code}{"start_op"},$hConn_ops{$c_code}{"end_op"});
    }else{
	  printf(OUT_FILE "【接続番号：%d】OP番号存在しません！\n",$c_code);
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
	$t_outFile = "$TOOL_DIR/ConnS_OP_Result_$str_time.log";
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
