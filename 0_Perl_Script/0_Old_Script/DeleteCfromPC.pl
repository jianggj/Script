######################################################################
#FileName:DeleteCfromPC.pl
#Description:指定されたフォルダに、PC生成したＣファイルを削除する。
######################################################################

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Next;
use Encode;
use File::Path;

#-------------------------------変数定義 Start-----------------------

# 本ツールの格納箇所
my $RESOURCES_DIR = dirname(__FILE__);
# 削除要ソースの格納箇所(Proc)
my $SOUR_FOLDER_DIR;
#時間
my $year;
my $mon;
my $mday;
my $hour;
my $min;
my $sec;
#pcファイル格納HASH
my %hPCFiles;
#------------------------------変数定義 End---------------------------

#------------------------------前処理 --------------------------------

#パラメータ(削除要ソースの格納箇所)を取得する
if(@ARGV == 1)
{
	$SOUR_FOLDER_DIR = shift;
}
#パースパース末尾に¥¥がない場合¥¥を追加
unless ( $SOUR_FOLDER_DIR =~ /¥¥$/ ) {
	$SOUR_FOLDER_DIR = "$SOUR_FOLDER_DIR¥¥";
}
#logファイルを開く
&logopen();
&logout( "DeleteCfromPC.pl", "Programe START!");
print "_/_/_/_/_/Programe START! _/_/_/_/_/¥n";

unless ( -e $SOUR_FOLDER_DIR )
{
	&logout("DeleteCfromPC.pl","【ERROR】解析先対象フォルダが存在していません！");
	die "解析先対象フォルダが存在していません。";
}

#------------------------------主処理 --------------------------------
print "PCファイル名取得開始・・・¥n";
#指定されたフォルダにすべてpcファイル名を検索する
my $pc_files = File::Next::files({file_filter =>¥&pc_file_filter,
								descend_filter => ¥&descend_filter}, $SOUR_FOLDER_DIR);
#pcファイル名取得して、HASHを保存
while ( defined( my $pc_file = $pc_files->() ) )
{
	unless ( -e $pc_file )
	{
		&logout($pc_file,"【ERROR】該当するファイルが存在していません！");
		next;
	}else{
		$pc_file =~ /(?:.*)¥¥(.*?)¥.pc/gi;
		my $pc_file_name = $1 ;
		$hPCFiles{$pc_file_name} = 1 ;
		&logout($pc_file,"【INFO】該当するファイルが記入しました。");
#		print $pc_file_name,"¥n";
	}
}

#指定されたフォルダにすべてcファイルを検索して、PC生成したＣファイルを削除する。
print "Ｃファイル検索開始・・・¥n";
my $c_files = File::Next::files({file_filter =>¥&c_file_filter,
								descend_filter => ¥&descend_filter}, $SOUR_FOLDER_DIR);
print "PC生成したＣファイル削除開始・・・¥n";
while ( defined( my $c_file = $c_files->() ) )
{
	$c_file =~ /(?:.*)¥¥(.*?)¥.c/gi;
	my $c_file_name = $1 ;
	#ファイルは、PC生成したＣファイルの場合、削除する。
	if(exists $hPCFiles{$c_file_name})
	{
		if (unlink $c_file) {
			&logout($c_file,"【INFO】該当するファイルは、C生成したＣファイルので、削除しました。" );
			print "$c_fileを削除しました!¥n";
		}else {
			&logout($c_file,"【ERROR】該当するファイルが削除できない！",);
		}
#	}else{
#		print "HASH存在しない！[$c_file_name]¥n";
	}
}
print "すべてのPC生成したＣファイルを削除¥n";
#------------------------------後処理 --------------------------------

print "_/_/_/_/_/Programe FINISH!_/_/_/_/_/¥n";
&logout( "DeleteCfromPC.pl", "Programe FINISH!");
&logclose();

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

	$logFile = "$RESOURCES_DIR¥¥DeleteCFromPC_$str_time.log";
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
	my ( $filename, $logMsg) = @_;
	my $str_time;

	# 日、月、年、週のみを取得する
	( $mday, $mon, $year ) = ( localtime(time) )[ 3 .. 5 ];
	# 秒、分、時のみを取得する
	( $sec, $min, $hour ) = ( localtime(time) )[ 0 .. 2 ];
	$year += 1900;
	$mon+= 1;
	$str_time = sprintf( "%4d-%02d-%02d %02d:%02d:%02d",
	$year, $mon, $mday, $hour, $min, $sec);
	$logMsg=~s/¥n//;

	#エンコードはUTF-8に変更する
	$logMsg = encode("UTF-8", decode("shiftjis",$logMsg) );

	printf( LOG_FILE "[%s ]	FileName:%s	%s¥n",$str_time, $filename, $logMsg );

}
#*************************************************************
#Function Name:c_file_filter()
#Description:PCソースのみを出力するフィルタ
#*************************************************************
sub pc_file_filter {
	# 呼び出し元：File::Next:files.
	# C言語のソースのみを出力するフィルタ
	/¥.pc$/
}
#*************************************************************
#Function Name:c_file_filter()
#Description:Cソースのみを出力するフィルタ
#*************************************************************
sub c_file_filter {
	# 呼び出し元：File::Next:files.
	# C言語のソースのみを出力するフィルタ
	/¥.c$/
}

#*************************************************************
#Function Name:descend_filter()
#Description:SVNと.hファイルを出力しないフィルタ
#*************************************************************
sub descend_filter {
	# 呼び出し元：File::Next:files.
	# SVNファイルを出力しないフィルタ
	$File::Next::dir !~ /¥.(svn|h)$/
}
