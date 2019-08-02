#######################   実行ステップ統計ツール   #############################
# 1> FileName:DeleteCfromPC.pl
# 2> Description:指定されたフォルダに、指定されたフラグ間のソース規模を統計出力。
# 3> 出力ファイル:
#		Change_Code_Count_Result.csv:ソース規模統計結果格納ファイル
#		ChangeCodeCount_log.csv		:プログラムのログメッセージ
# 4> 実施:
#	 ①：cmd
#	 ②：＞ツール 解析要フォルダ	例えば：E:>ChangeCodeCount.pl E:\CDI
# 5> 制限事項: 単行改修ソースの規模統計は、精確ではありません。
################################################################################

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Next;
use Encode;
use File::Path;
use Encode::Guess;


#-------------------------------変数定義 Start-----------------------

# 本ツールの格納箇所
my $RESOURCES_DIR = dirname(__FILE__);
# 解析要ソースの格納箇所(Proc)
my $SOUR_FOLDER_DIR;
#結果格納ファイル
my $ResultFile;
#時間
my $year;
my $mon;
my $mday;
my $hour;
my $min;
my $sec;

my @lines;
#読み取るファイルの現在の番号
my $ReadFileLine_now = 0;
#ソースの規模:実行ステップ
my $SourceCount_normalLine = 0;
#ソースの規模:コメント
my $SourceCount_commentLine = 0;
#ソースの規模:空白行
my $SourceCount_whiteLine = 0;

#ソースの規模合計用:実行ステップ
my $Total_normalLine = 0;
#ソースの規模合計用:コメント
my $Total_commentLine = 0;
#ソースの規模合計用:空白行
my $Total_whiteLine = 0;
#単行改修ソースの規模(精確ではありません)
my $Single_normalLine = 0;
#単行改修制御(0:出力不要,1：出力要)
my $Single_Change_Flag = 0;

#判断フラグ
my $doubleflag = 0;
#結果判断フラグ
my $success = "true";

#*****区分キーテスト*****
	my $flgstr1 = "ADD 31.0.0.0";
	my $startconst1 = "↓";
	my $endconst1 = "↑";

	my $flgstr2 = " 31.0.0.0";
	my $startconst2 = "==>";
	my $endconst2 = "<==";

	my $flgstr3 = " 31.0.0.0";
	my $startconst3 = "開始";
	my $endconst3 = "終了";
#=comment_start
	my $flgstr4 = " 31.0.0.0";
	my $startconst4 = "region==>";
	my $endconst4 = "endregion<==";

	my $flgstr5 = " 31.0.0.0";
	my $startconst5 = "START";
	my $endconst5 = "END";
#=cut
 my $singleflag = " 31.0.0.0";
#------------------------------変数定義 End---------------------------

#------------------------------前処理 --------------------------------

#パラメータ(解析要ソースの格納箇所)を取得する
if(@ARGV == 1)
{
	$SOUR_FOLDER_DIR = shift;
}
#パースパース末尾に\\がない場合\\を追加
unless ( $SOUR_FOLDER_DIR =~ /\\$/ ) {
	$SOUR_FOLDER_DIR = "$SOUR_FOLDER_DIR\\";
}

#結果格納ファイル
$ResultFile = "$RESOURCES_DIR\\Change_Code_Count_Result.csv";

#logファイルを開く
&logopen();
&logout( "ChangeCodeCount.pl","【PJ】", "Programe START!");
print "_/_/_/_/_/Programe START! _/_/_/_/_/\n";

unless ( -e $SOUR_FOLDER_DIR )
{
	&logout("ChangeCodeCount.pl","【ERROR】","解析先対象フォルダ[$SOUR_FOLDER_DIR]が存在していません！");
	die "解析先対象フォルダが存在していません。\n";
}
#結果格納ファイルを開く
open RESULT_FILE,">$ResultFile" or die "Cannot open $ResultFile: $!\n";
print RESULT_FILE "\"パス\",\"ファイル名\",\"実行ステップ\",\"コメント\",\"空白行\"\n";
#------------------------------主処理 --------------------------------
print "指定されたフォルダ読み込み開始・・・\n";
#指定されたフォルダにすべてファイル名を取得する
my $files = File::Next::files({file_filter =>\&file_filter,
								descend_filter => \&descend_filter}, $SOUR_FOLDER_DIR);

while ( defined( my $file = $files->() ) )
{
	#ファイルのパス
	my $FILE_PATH = dirname($file);
	#パス中、ファイル名を取得
	my @FileName = split /\\/,$file;
	my $FileName = pop(@FileName);

	unless ( -e $file )
	{
		&logout($file,"【WARNING】","該当するファイルが存在していません！");
		print "【WARNING】ファイル[$FileName]は、存在していません！次のファイル読む。";
		next;
	}

	eval {
		# 該当するCソースを開く
		open IN, "$file" or die "Can't open '$file': $!\n";
		# 該当するCソースの内容を$lineに格納する
		my $line = do { local $/; <IN> };
		close IN;
		# 該当するCソースの内容があった場合
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
		&logout($file,"【ERROR】","ファイルの読み込みに例外が発生しました!");
		&logout( "ChangeCodeCount.pl","【PJ】", "Programe FINISH[fail]!\n");
		die "【ERROR】:ファイル[$FileName]の読み込みに例外が発生しました！\n詳細：$@\n";
		#&logout("ERROR","ファイルの読み込みに例外が発生しました。【Method：SearchFunctionIsNeverUsed 詳細：$@】", __LINE__);
		#next;
	}
	#読み取るファイルの番号初期化
	$ReadFileLine_now = 0;
	foreach my $splitLine (@lines)
	{
		$ReadFileLine_now++;#読み込み番号
		#-----------------エンコード形式変換 start
		eval
		{
			#エンコード形式変換:UTF-8 ==> shiftjs
			my $enc = Encode::Guess->guess( $splitLine );
			if ( $enc  =~/utf8/i)
			{
				$splitLine = encode("shiftjis", decode("UTF-8",$splitLine) );
#				&logout($file,"【INOF】","エンコード形式変換(UTF-8==>shiftjis)。行番号：$ReadFileLine_now");
			}

		};
		if($@)
		{
			&logout($file,"【ERROR】","エンコード形式変換中例外が発生しました!");
			&logout( "ChangeCodeCount.pl","【PJ】", "Programe FINISH[fail]!\n");
			die "【ERROR】:ファイル[$FileName]エンコード形式変換中例外が発生しました！行番号：$ReadFileLine_now\n詳細：$@\n";
		}
		#-----------------エンコード形式変換 end

		#単行改修 !!精確ではありません!!
		if($Single_Change_Flag && $doubleflag == 0)
		{
			my $Singleline = $splitLine;
			$Singleline =~s/^\s+//g;
			if( (($Singleline =~ /\/\//i) && ($Singleline =~ /$singleflag/i)) &&
				!(	($Singleline =~ /$startconst1/i) ||
					($Singleline =~ /$startconst2/i)||
					($Singleline =~ /$startconst3/i)||
					($Singleline =~ /$startconst4/i)||
					($Singleline =~ /\b$startconst5\b/i)||
					($Singleline =~ /$endconst1/i)||
					($Singleline =~ /$endconst2/i)||
					($Singleline =~ /$endconst3/i)||
					($Singleline =~ /$endconst4/i)||
					($Singleline =~ /\b$endconst5\b/i)	) )
					{
						$Single_normalLine++;
						&logout($file,"【INOF】","単行改修。行番号：$ReadFileLine_now");
						next;
					}
		}

		#多行改修
		if( (($splitLine =~/$flgstr1/i)&&($splitLine =~ /$startconst1/i)) ||
		    (($splitLine =~/$flgstr2/i)&&($splitLine =~ /$startconst2/i)) ||
		    (($splitLine =~/$flgstr3/i)&&($splitLine =~ /$startconst3/i)) ||
		    (($splitLine =~/$flgstr4/i)&&($splitLine =~ /$startconst4/i)) ||
		    (($splitLine =~/\b$flgstr5\b/i)&&($splitLine =~ /\b$startconst5\b/i)) )
		{
			if($doubleflag == 0)
			{
				&logout($file,"【INOF】","改修開始フラグ。行番号：$ReadFileLine_now");
			}
			$doubleflag++;
			next;
		}
		if( (($splitLine =~/$flgstr1/i)&&($splitLine =~ /$endconst1/i)) ||
		    (($splitLine =~/$flgstr2/i)&&($splitLine =~ /$endconst2/i)) ||
		    (($splitLine =~/$flgstr3/i)&&($splitLine =~ /$endconst3/i)) ||
		    (($splitLine =~/$flgstr4/i)&&($splitLine =~ /$endconst4/i)) ||
		    (($splitLine =~/$flgstr5/i)&&($splitLine =~ /\b$endconst5\b/i)) )
		{
			$doubleflag--;
			if($doubleflag == 0)
			{
				&logout($file,"【INOF】","改修終了フラグ。行番号：$ReadFileLine_now");
			}
			next;
		}
		if($doubleflag > 0)
		{
			&parse($splitLine);
		}elsif($doubleflag < 0)
		{
			&logout($file,"【ERROR】","終了フラグの数量を超える！行番号：$ReadFileLine_now");
			die "【ERROR】:ファイル[$FileName]に終了フラグの数量を超えることを存在しました！行番号：$ReadFileLine_now　\n";
		}
	}
	if($doubleflag)
	{
		&logout($file,"【ERROR】","フラグが２倍ではない、計算できないですので、チェックしてください!");
		&logout( "ChangeCodeCount.pl","【PJ】", "Programe FINISH[fail]!\n");
		die "【ERROR】:ファイル[$FileName]フラグが２倍ではない、計算できないですので、チェックしてください!\n";
	} elsif($doubleflag != 0)
	{
		&logout($file,"【ERROR】","フラグが問題（非0）を存在ので、プログラム中止!");
		&logout( "ChangeCodeCount.pl","【PJ】", "Programe FINISH[fail]!\n");
		die "【ERROR】:ファイル[$FileName]フラグが問題（非0）を存在ので、プログラム中止!\n";
	}else
	{
		printf( "[Result]ファイル名：%s ,実行ステップ：%s ,コメント：%s ,空白行：%s \n",$FileName, $SourceCount_normalLine, $SourceCount_commentLine, $SourceCount_whiteLine);
		printf( RESULT_FILE "%s ,%s ,%s ,%s ,%s\n",$FILE_PATH,$FileName, $SourceCount_normalLine, $SourceCount_commentLine, $SourceCount_whiteLine);
	}
	#記数初期化
	$SourceCount_normalLine = 0;
	$SourceCount_commentLine = 0;
	$SourceCount_whiteLine = 0;
	$doubleflag = 0;


}
#結果合計
print "\n"x3;
printf( "[Result 合計]\n実行ステップ：%s \nコメント：%s \n空白行：%s \n", $Total_normalLine, $Total_commentLine, $Total_whiteLine);
if($Single_Change_Flag)
{
	printf( "単行改修(精確ではありません):%s\n",$Single_normalLine);
}
print "\n"x3;

print RESULT_FILE "\n"x3;
print RESULT_FILE "[Result 合計]\n";

printf( RESULT_FILE "実行ステップ,%s\n",$Total_normalLine);
printf( RESULT_FILE "コメント,%s\n",$Total_commentLine);
printf( RESULT_FILE "空白行,%s\n",$Total_whiteLine);
if($Single_Change_Flag)
{
	printf( RESULT_FILE "単行改修(精確ではありません),%s\n",$Single_normalLine);
}
print "規模統計完了！\n";
#------------------------------後処理 --------------------------------

close RESULT_FILE;
print "_/_/_/_/_/Programe FINISH!_/_/_/_/_/\n";
&logout( "ChangeCodeCount.pl","【PJ】", "Programe FINISH[success]!\n");
&logclose();

#*************************************************************
#Function Name:parse()
#Description:各行ソースは構文解析
#Parameters:ソース（行）
#*************************************************************
sub parse($)
{
	my $line = shift;
	#コメントのフラグ
	my $commentflag = "false";
	if($line =~/^(\s)*$/)
	{
		$SourceCount_whiteLine++;
		$Total_whiteLine++;
	}else
	{
		#行頭の空文字を除く
		$line =~ s/^\s+//g;
		#行尾の空文字を除く
		#$line =~ s/\s+$//g;
		if($line =~ /^\'/)
		{
			$SourceCount_commentLine++;
			$Total_commentLine++;
		}elsif($line =~ /^\/\*(.*)\*\//)
		{
			$SourceCount_commentLine++;
			$Total_commentLine++;
		}elsif(($line=~ /^\/\*/)&&!($line =~/\*\/$/))
		{
			$SourceCount_commentLine++;
			$Total_commentLine++;
			$commentflag = "true";
		}elsif($commentflag eq "true")
		{
			$SourceCount_commentLine++;
			$Total_commentLine++;
			if($line =~ /\*\/$/)
			{
				$commentflag = "false";
			}
		}elsif($line =~ /^\/\//)
		{
			$SourceCount_commentLine++;
			$Total_commentLine++;
		}else
		{
			$SourceCount_normalLine++;
			$Total_normalLine++;
		}

	}
}
#*************************************************************
#Function Name:logopen()
#Description:ログファイルを開く
#*************************************************************
sub logopen() {
	my $logFile;
	# 日、月、年、週のみを取得する
	# 秒、分、時のみを取得する
	( $sec, $min, $hour, $mday, $mon, $year) = ( localtime(time) )[ 0 .. 5 ];
	$year += 1900;
	$mon+= 1;
	my $str_time = sprintf( "%4d%02d%02d%02d%02d%02d",$year, $mon, $mday, $hour, $min, $sec);

	$logFile = "$RESOURCES_DIR\\ChangeCodeCount_log.csv";
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
#Parameters:エラーが発生したファイル名、出力するログメッセージ
#*************************************************************
sub logout(@) {
	# パラメータを取得する
	my ( $filename,$logType, $logMsg) = @_;
	my $str_time;

	# 日、月、年、週のみを取得する
	( $mday, $mon, $year ) = ( localtime(time) )[ 3 .. 5 ];
	# 秒、分、時のみを取得する
	( $sec, $min, $hour ) = ( localtime(time) )[ 0 .. 2 ];
	$year += 1900;
	$mon+= 1;
	$str_time = sprintf( "%4d-%02d-%02d %02d:%02d:%02d",
	$year, $mon, $mday, $hour, $min, $sec);
	$logMsg=~s/\n//;

	#エンコードはUTF-8に変更する
	$logMsg = encode("UTF-8", decode("shiftjis",$logMsg) );
	$logType = encode("UTF-8", decode("shiftjis",$logType) );

	printf( LOG_FILE "[%s ]	,%s,FileName:%s	,%s\n",$str_time,$logType, $filename, $logMsg );

}
#*************************************************************
#Function Name:file_filter()
#Description:解析要ソースのファイル種類を設定
#*************************************************************
sub file_filter {
	# 呼び出し元：File::Next:files.
	/\.(h|cs|cpp|rc|c)$/i
}

#*************************************************************
#Function Name:descend_filter()
#Description:解析不要ソースのファイル種類を設定
#例えば：SVNファイルを出力しないフィルタ
#*************************************************************
sub descend_filter {
	# 呼び出し元：File::Next:files.
	# SVNファイルを出力しないフィルタ
	$File::Next::dir !~ /\.svn$/i
}
