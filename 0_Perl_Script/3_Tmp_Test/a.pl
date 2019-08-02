#!/usr/bin/perl -w
######################################################################
#FileName: .pl
#Description:
######################################################################

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Next;
use File::Path;

#-------------------------------変数定義 Start-----------------------

# 本ツールの格納箇所
my $RESOURCES_DIR = dirname(__FILE__);
# 解析先対象フォルダ格納箇所
my $SOUR_FOLDER_DIR;
#時間
my $year;
my $mon;
my $mday;
my $hour;
my $min;
my $sec;
#内容を配列@lines
my @lines =();
#------------------------------変数定義 End---------------------------

#------------------------------前処理 --------------------------------
print "_/_/_/_/_/Programe START! _/_/_/_/_/\n";
#logファイルを開く
&logopen();
&logout( "Main Programe", "Programe START!"); 
print "解析先対象フォルダチェック・・・\n";
#パラメータ(解析先対象フォルダ格納箇所)を取得する
if(@ARGV == 1)
{
	$SOUR_FOLDER_DIR = shift;
}
#パース末尾に/がない場合/を追加
unless ( $SOUR_FOLDER_DIR =~ /\/$/ ) {
	$SOUR_FOLDER_DIR = "$SOUR_FOLDER_DIR\/";
}

unless ( -e $SOUR_FOLDER_DIR )
{
	&logout("Main Programe","【ERROR】解析先対象フォルダが存在していません！");
	die "解析先対象フォルダが存在していません。";
}

#------------------------------主処理 --------------------------------
print "フォルダに指定されたファイル読み込み・・・\n";
#指定されたフォルダにすべてファイル名読み込み開始
my $files = File::Next::files({file_filter =>\&pc_file_filter,
								descend_filter => \&descend_filter}, $SOUR_FOLDER_DIR);
print "処理中・・・\n";
while ( defined( my $file = $files->() ) )
{
	unless ( -e $file )
	{
		&logout($file,"【ERROR】該当するファイルが存在していません！");
		next;
	}
	{
	    #処理...
		&logout($file,"【INFO】該当するファイル読み込み開始");
		&File_Contents_Read($file);
		&logout($file,"【INFO】該当するファイル処理完了");
		&File_Line_Process();
	}
}

#------------------------------後処理 --------------------------------

print "_/_/_/_/_/Programe FINISH!_/_/_/_/_/\n";
&logout( "Main Programe", "Programe FINISH!");
&logclose();

#------------------------------関   数--------------------------------
#*************************************************************
#Function Name:File_Line_Process
#Description:ファイルの内容が、行に対して、処理を実行する
#*************************************************************
sub File_Line_Process(){
    foreach my $splitLine (@lines)
	{
	    #行処理を行う
		print "$splitLine\n";
	}
}

#*************************************************************
#Function Name:File_Contents_Read()
#Description:ファイルの内容が変数に読み込む
#*************************************************************
sub File_Contents_Read($){
	# パラメータを取得する
	my $filename = shift;
    @lines = ();
	eval {
	    # 該当するファイルを開く
		open IN, "$filename" or die "Can't open '$filename': $!\n";
		# 該当するファイルの内容を$lineに格納する
		my $line = do { local $/; <IN> };
		close IN;
		# 該当するファイルの内容があった場合
		if ($line)
		{
		    # 該当するファイルに改行コードを文字列「¶CR_LF_SPLITSTRING¶」に置換する
			$line =~ s/\r|\r\n|\n|\cJ|\cM/CR_LF_SPLITSTRING/g;
			$line =~ s/\cI/ /g;

			# 文字列「CR_LF_SPLITSTRING」によって、行ごとに内容を配列@linesに格納する
			@lines = split /CR_LF_SPLITSTRING/ , $line;
		}
	};
	if ($@)
	{
	    #読み込みに例外が発生の場合、処理中止
		&logout($filename,"【ERROR】","ファイルの読み込みに例外が発生しました!");
		&logout( "Main Programe", "Programe FAIL!");
		die "【ERROR】:ファイル[$filename]の読み込みに例外が発生しました！\n詳細：$@\n";
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

	$logFile = "$RESOURCES_DIR/Tool_Log_$str_time.log";
	open( LOG_FILE, ">>$logFile" );
	print "本ツールの実行ログ：$logFile\n";
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
	$logMsg=~s/\n//;


	printf( LOG_FILE "[%s ]	\t%-30s\t%-s\n",$str_time, $filename, $logMsg );

}
#*************************************************************
#Function Name:pc_file_filter()
#Description:出力したいファイルのタイプを指定する
#*************************************************************
sub pc_file_filter {
	# 呼び出し元：File::Next:files.
	# logとpcファイルのみを出力するフィルタ
	/\.(pc|log)$/
}

#*************************************************************
#Function Name:descend_filter()
#Description:出力しないファイルタイプ（SVNと.h）を指定する
#*************************************************************
sub descend_filter {
	# 呼び出し元：File::Next:files.
	# SVNファイルを出力しないフィルタ
	$File::Next::dir !~ /\.(svn|h)$/
}
