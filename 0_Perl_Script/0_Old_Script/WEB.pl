#********************************************************************************************************
#FileName:CreateMobileHomePageTool.pl
#Description:
#[CreateMobileHomePageTool.pl] can convert from 'Desktop Browser web page' into
#'Mobile web page',and backup the original source files which have been modified.
#********************************************************************************************************
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::Next;
use Encode;
use Archive::Zip;
use File::Path;
use File::Path;

# debug log mode
# 0:output
# 1:not output
my $DEBUG_MODE = "0";
my $RESOURCES_DIR = dirname(__FILE__);
my $ZIPFILENAME = "BackupSource.zip"; # 生成したい圧縮ファイル

my $OPTION;
my $SOUR_FOLDER_DIR;

my $start=time;
&logopen();

#パラメータをチェック
if ( @ARGV != 2 ) {
  &ShowUsage();
  &logout("ERROR","number of parameters is incorrect,you should enter two parameters.[Method：Main]", __LINE__);
  die "\n[ERROR]:number of parameters is incorrect,you should enter two parameters.\n";
}
else {
	($OPTION, $SOUR_FOLDER_DIR) = @ARGV;
	$_ = $OPTION;
	SWITCH: {
		/^all$/i && do { &AutoExecCommand(); last SWITCH; };
		/^b$/i && do { &BackupCommand(); last SWITCH; };
		/^c$/i && do { &ConvertSourceCommand(); last SWITCH; };
		/^k$/i && do { &SwitchBackCommand(); last SWITCH; };
		&logout("ERROR","inputed [OPTION] is incorrect,you should enter [all],[b],[c],[k].", __LINE__);
		die "\n[ERROR]:inputed [OPTION] is incorrect,you should enter [all],[b],[c],[k].\n";
	}
}

&logclose();

#*************************************************************
#Function Name:ShowUsage()
#Description:取り扱い説明を行う
#*************************************************************
sub ShowUsage {
print STDOUT << "EOF";
#######################################################################################
Describe:[CreateMobileHomePageTool.pl] can convert from 'Desktop Browser web page'
into 'Mobile web page',and backup the original source files which have been modified.

If there is something wrong in the coverted source,
you can switch back the source that you have just modified.

Usage: CreateMobileHomePageTool.pl [OPTION] [FOLDER NAME]

Examples:
CreateMobileHomePageTool.pl all D:\\necsoft
CreateMobileHomePageTool.pl b   D:\\necsoft
CreateMobileHomePageTool.pl c   D:\\necsoft
CreateMobileHomePageTool.pl k   D:\\necsoft

Main operation mode:
all            backup and convert.
b              [b]ackup source files.
c              [c]onvert from 'Desktop Browser web page' into 'Mobile web page'.
k              switch bac[k].
[FOLDER NAME]  name of the Desktop Browser web page source with full path.
#######################################################################################
EOF
}

#*************************************************************
#Function Name:autoExecCommand()
#Description:CreateMobileHomePageToolを自動的に行う
#						ステップ１：バックアップ
#						ステップ２：ソース変換
#*************************************************************
sub AutoExecCommand() {

	print "PRODUCTION MOBILE ENVIRONMENT CONVERT! target dir = $SOUR_FOLDER_DIR.\n";
	print "Are you sure to continue?(y/n)\n";
	chomp($_ = <STDIN>);
	if(/y/i) {
		BackupSourceCommand($SOUR_FOLDER_DIR);
		ConvertSourceCommand();
	}else{
		exit;
	}
}

#------------------------------------------------------------------------------
# ConvertSource
# 指定されたソースファイルの名前を変更する
#------------------------------------------------------------------------------
sub ConvertSourceCommand() {

	my $data;
	my $line;
	my @lines;
	my $newFileName;
	my $newFileContent;
	my $count = 0;
	my $count_img =0;


	# GUI環境設定画面にて指定された機能フォルダ一覧ごとに、すべてjavaソースを検索する
	my $files = File::Next::files({file_filter =>\&HtmlFileFilter,
			descend_filter => \&DescendFilter}, $SOUR_FOLDER_DIR);

	# 指定されたHTMLソースごとに、下記の処理を行う
	while ( defined( my $file = $files->() ) ) {
		unless ( -e $file ) {
			&logout("ERROR","該当するファイルが存在していません。【Method：ConvertSourceCommand 詳細：$file】", __LINE__);
			next;
		}

		if ($file =~ /\Qindex.html_host=www.necsoft.com.cn&src=http_%2F%2F\E(www.necsoft.com.cn%2F)*(.*)/){
			$newFileName = $2;
			$newFileName =~ s/\Q%2F\E/\\/gi;
			$newFileName = $SOUR_FOLDER_DIR."\\".$newFileName;
			#$newFileName =~ s/\\/\//gi;
			#--------------begin------------------
			#"\"の数量計算
			my $count_titol = $newFileName =~ s/\\/\//gi;
			my $root=$SOUR_FOLDER_DIR;
			my $count_root = $root =~ s/\\/\//gi;
			$count = $count_titol - $count_root-1;
			$count_img = $count_titol - $count_root;
			print "$newFileName	[$count|$count_img]\n";
			#---------------end-------------------
		}else{
			print "=====$file\n";
		}
		
		my $point = "\.\./";
		my $position = "";
		$position=$point x $count;
		my $position_img = $point x $count_img;
		$count= 0;
		$count_img = 0;
		eval {
			$data = "";
			# 該当するJAVAソースを開く
			open IN, "$file" or die "Can't open '$file': $!";
			# 該当するJAVAソースの内容を$lineに格納する
			$line = do { local $/; <IN> };
			close IN;
			
			#--------------begin------------------
			#共通css抽出
			if ($line){
#				# 該当するJAVAソースに改行コードを文字列「CR_LF_SPLITSTRING」に置換する
				$line =~ s/\r|\r\n|\n/CR_LF_SPLITSTRING/g;
#				# 文字列「CR_LF_SPLITSTRING」によって、行ごとにソースを配列@linesに格納する
#				@lines = split /CR_LF_SPLITSTRING/ , $line;
			}
			my $cssfile= $SOUR_FOLDER_DIR."\\css/style.css";
			$cssfile =~ s/\\/\//gi;
			my $csspath_a = "<link rel=\"stylesheet\" type=\"text/css\" href=\"";
			my $csspath_b = "css/style.css\"/>";
			if(!-e $cssfile)
			{
				my $newFileDir = dirname($cssfile);
				mkpath $newFileDir;
				# 読み書きモードでオープン
				if (!open(CSSFILE, "+<$cssfile"))
				{
					# ファイルが無ければ新規作成
					open(CSSFILE, "+>$cssfile") or die($!);
				}
				$line =~ s^(<style type="text/css">CR_LF_SPLITSTRING\t*(.*)</style>)^$csspath_a$position$csspath_b^gi;
				my $css=$1;
				$css =~ s^CR_LF_SPLITSTRING^\n^gi;
				$line =~ s^CR_LF_SPLITSTRING^\n^gi;
				#先頭空白削除
				$css =~ s^text-indent:2em;^/*text-indent:2em;*/^gi;
				#タイトのフォントサイズを修正
				$css =~ s^font-size: 40px;^font-size: 16px;^gi;
				print CSSFILE $css;
				close(CSSFILE);
			}else{
			
			$line =~ s^(<style type="text/css">CR_LF_SPLITSTRING\t*(.*)</style>)^$csspath_a$position$csspath_b^gi;
			$line =~ s^CR_LF_SPLITSTRING^\n^gi;
				}
			#---------------end-------------------
		};
		if ($@) {
			#ログファイルに出力する
			&logout("ERROR","ファイルの読み込みに例外が発生しました。【Method：createJavaMethodList 詳細：$@】", __LINE__);
			next;
		}
			#print "$line\n";

		#--------------begin------------------
		#紹介ページdivエラー修正 span修正
		if($line =~ /\QNEC软件(济南)有限公司介绍\E/)
		{
		  if ($line =~ /<div>(<span   class\=\" tc-f3\">(.*?)<\/span>)+<\/div>/)
		  {
			  $line =~ s^<div>((?:<span   class\=\" tc-f3\">(.*?)</span>)+)</div>^\[div\]$1\[/div\]^gi;
			  $line =~ s^<span   class\=\" tc-f3\">(.*?)</span>^$1^gi;
			  $line =~ s^\[/div\]\[div\]^^gi;
			  $line =~ s^\[div\]^<div>^gi;
			  $line =~ s^\[/div\]^</div>^gi;
		  }
		}
		#---------------end-------------------
		
		#--------------begin------------------
		#『总经理致辞』ページのspan修正
		if($line =~ /\Q总经理致辞\E/)
		{
			$line =~ s^<span   class\=\" tc-f3\">(.*?)</span>^$1^gi;
		}
		#---------------end-------------------
		#--------------begin------------------
		if($line =~ /\Q业务内容\E/)
		{
			$line =~ s^(<li(?:.*?)"ellipsis">)业务内容^$1产品方案^gi;
		}
		#---------------end-------------------

		# 取得されたJAVAソースから、クラス名を取得する
		$line =~ s!(href\=(?:'|"))http:(?:\/|%252F)+(?:siteapp|m).baidu.com(?:\/|%252F)+site(?:\/|%252F)+www.necsoft.com.cn(?:\/|%252F)+(?:index.html)?\?host=www.necsoft.com.cn&amp;src=http:(?:\/|%252F)+(?:www.necsoft.com.cn(?:\/|%252F)+)*(.*?)('|")!$1$position$2$3!gi;
		$line =~ s!\Q%252F\E!/!gi;
		#cbusiness/b_intro/index.html
		$line =~ s^(href\=(?:'|"))http:(?:\/|%252F)+m.baidu.com(?:\/|%252F)+error.jsp\?host=www.necsoft.com.cn&amp;src=http:?(?:\/|%3A%2F%2F)+(?:www.necsoft.com.cn(?:\/|%2F)+)*(.*?)('|")^$1$position$2$3^gi;
		$line =~ s^%2F^\/^gi;
		$line =~ s^(href\=(?:'|"))http:(?:\/|%252F)+www.necsoft.com.cn(?:\/\w+)*\.html\?host\=www.necsoft.com.cn&amp;src\=http(?:%3A%2F%2F|/)+(?:www.necsoft.com.cn(?:\/|%2F)+)*(.*?)('|")^$1$position$2$3^gi;
		#cnews/history/index1~n.html
		$line =~ s^(href\=(?:'|"))index.html\?host=www.necsoft.com.cn&amp;src=http:?(?:\/|%3A%2F%2F)+(?:www.necsoft.com.cn(?:\/|%2F)+)*(.*?)('|")^$1$position$2$3^gi;

		#--------------begin------------------
		#写真のパスを修正
		$line =~ s^%2E^\.^gi;
		$line =~ s^(<img(?:\s)*src\=")http://tc2.baidu-1img.cn/timg\?pa&amp;quality=(?:.*?)src=http%3A//www.necsoft.com.cn/((?:.*?)\.(?:jpg|png|gif|bmp)")^$1$position_img$2^gi;
		$line =~ s^(<a(?:\s)*href\=")http://www.necsoft.com.cn/((?:.*?)\.(?:jpg|bmp)")^$1$position_img$2^gi;
		#---------------end-------------------

		#--------------begin------------------
		#ページ迁移修正：
		#   ボタン削除、モバイル版ページに迁移
		
		#迁移制御
		$line =~ s^<form action\="http:\/\/siteapp.baidu.com\/site\/www.necsoft.com.cn\/\?"^<form ^gi;
		$line =~ s^(<select(?:.*?))style=" "(\t)*^$1 onchange\="self.location.href=options\[selectedIndex\]\.value"^gi;
		#アドレス変換
		$line =~ s^(<option value\=")http://www.necsoft.com.cn/(.*?)("(?:selected\="selected")?>)^$1$position$2$3^gi;
		#ボタン と 隠された入力枠 削除
		#$line = s/<input type(.*?)>//gi;
		$line =~ s/<input(.*?)((value\="跳"(.*)?)|value\="www.necsoft.com.cn")>//gi;
		#---------------end-------------------
		
		#--------------begin------------------
		#『联系我们』ページの線を修正
		if($line =~ /\Q联系我们\E/)
		{
			$line =~ s^(info\@necsoft.com.cn(?:.*?)<div)>(?:.*?)-*<\/div>^$1 align\="center"><hr>^gi;
			$line =~ s^<div><span   class\=" tc\-f3">(?:\―)*<\/span>((?:.*?)地址)^<hr>$1^gi;
		}
		#---------------end-------------------

		#--------------begin------------------
		#空白ページ削除
		if( $newFileName =~ m^(index14|index18|index12|cinvite/inv_infor/index\.html)^)
		{
			$line =~ s^<div class="yi-normal"(.*?)(2009-11-18|2009-12-07|2010-01-21|2014-01-21|2008-01-21|2010-12-20)(.*?)\n\n(.*?)(1145150550|1000628527|1335447626|2111930287|1257894452|1741251533|170758259)(.*?)<\/div><\/div>^^gi;
		}
		if($newFileName =~ m^(cnews/history/index7|cnews/history/index4|cnews/history/index3|cnews/history/index9|cintro/honor/index|cintro/honor/index3)^)
		{
			$line =~ s^<div><span class="tc-normal-distance1"><span   class="time tc-f3">(2011-10-19|2012-09-06|2012-10-31|2011-08-09|2014-01-16|2007-07-09)(.*?)(1948154910|2008235589|714368020|726064803|504356265|1979216241)(.*?)<\/div>^^gi;
		}
		if($newFileName =~ m^(cculture/stu_pub/index|cpartner/par_intro/index)^)
		{
			$line =~ s^<div><span   class="time tc-f3">(2010-09-01|2009-02-23)(.*?)(1098839845|1164410773)(.*?)<\/div>^^gi;
		}
		if($newFileName =~ m^testTool/index\.html^)
		{
			$line =~ s^<li class="yi-list-li">(.*?)1257894452(.*?)\n<\/div><\/li>^^gi;
			$line =~ s^(www.jinan.gov.cn|www.qilusoft.org|www.jn.gov.cn|chinasourcing.mofcom.gov.cn)^http://$1^gi;
		}
		#---------------end-------------------
		if ($newFileName){
			my $newFileDir = dirname($newFileName);
			mkpath $newFileDir;

			# 読み書きモードでオープン
			if (!open(DATAFILE, "+<$newFileName"))
			{
				# ファイルが無ければ新規作成
				open(DATAFILE, "+>$newFileName") or die($!);
			}

			print DATAFILE $line;
			close(DATAFILE);

			if (unlink $file) {
				&logout("INFO","file[$file] is deleted.[Method：ConvertSourceCommand]", __LINE__);
			}else {
				&logout("WARN","file[$file] can not deleted.[Method：ConvertSourceCommand]", __LINE__);
			}
		}
	}
}

#------------------------------------------------------------------------------
# ZIP化
# addFileは引数のファイルを、addTreeは第１引数のフォルダをZIP圧縮する。
#------------------------------------------------------------------------------
sub BackupSourceCommand($) {
	my $dirname = shift; # 圧縮対象ディレクトリ名

	if (-d $RESOURCES_DIR){
		# オブジェクト作成
		my $zip = Archive::Zip->new();
		# 圧縮するディレクトリを指定（第二引数省略：解凍先領域指定時のみ必要）
		$zip->addTree($dirname);

		# Zipファイルに書き出す
		my $status = $zip->writeToFileNamed("$RESOURCES_DIR/$ZIPFILENAME");
	}else{
		die "the backup destination folder [$RESOURCES_DIR] is not exist: $!";
	}
}

#------------------------------------------------------------------------------
# UNZIP化
# zipfileは解凍されるファイル名を指定する。
# 解凍されるファイルが存在しなかった場合、エラーメッセージが表示される。
#------------------------------------------------------------------------------
sub SwitchBackCommand() {
	my $zipfile = "$RESOURCES_DIR/$ZIPFILENAME";

	if (-f $zipfile){
		my $zip = Archive::Zip->new($zipfile);
		my @members = $zip->memberNames();
		foreach (@members) {
			$zip->extractMember($_, "$SOUR_FOLDER_DIR/$_");
		}
	}else{
		&logout("ERROR","file is no exist.[Method:ReleaseArchiveDir][zipFile=$zipfile]", __LINE__);
		die "\n[ERROR]:file is no exist.[Method：ReleaseArchiveDir][zipFile=$zipfile].\n";
	}
}

#*************************************************************
#Function Name:logopen()
#Description:ログファイルを開く
#*************************************************************
sub logopen() {
  my $logFile = "$RESOURCES_DIR\\CreateMobileHomePageTool.log";
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
  my $currentSourceName = "CreateMobileHomePageTool.pl";

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
  $logMsg=~s/\n//;

  #エンコードはUTF-8に変更する
  $logMsg = encode("UTF-8", decode("shiftjis",$logMsg) );
  # ログファイル追加モードでオープン
  if ( ( uc($logType) eq "DEBUG" ) && ( $DEBUG_MODE eq "1" ) ) {
    printf( LOG_FILE "%s %s %d %s: %s\n",
    $str_time, $currentSourceName, $line, uc($logType), $logMsg );
  }
  elsif ( uc($logType) eq "INFO" ) {
    printf( LOG_FILE "%s %s %d %s: %s\n",
    $str_time, $currentSourceName, $line, uc($logType), $logMsg );
  }
  elsif ( uc($logType) eq "ERROR" ) {
    printf( LOG_FILE "%s %s %d %s: %s\n",
    $str_time, $currentSourceName, $line, uc($logType), $logMsg );
  }
}

#*************************************************************
#Function Name:deleteCommentFromJavaSource()
#Description:JAVAソースのコメントを除いて、ソース本体を取得
#*************************************************************
sub deleteCommentFromJavaSource($){
  my $lines = shift;

  my $data;
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
    $data .= "$_ ";
  }

  return $data;
}

#*************************************************************
#Function Name: HtmlFileFilter()
#Description:JAVAソースのみを出力するフィルタ
#*************************************************************
sub HtmlFileFilter { 
    # 呼び出し元：File::Next:files.
    # JAVAソースのみを出力するフィルタ
    /.(html|jpg)$/
}

#*************************************************************
#Function Name:DescendFilter()
#Description:SVNファイルを出力しないフィルタ
#*************************************************************
sub DescendFilter { 
    # 呼び出し元：File::Next:files.
    # SVNファイルを出力しないフィルタ
    $File::Next::dir !~ /.svn$/
}
#時間統計
my $sec_s;
my $min_s;
my $hour_s;
my $sec_n;
my $min_n;
my $hour_n;
my $sec_a;
my $min_a;
my $hour_a;
( $sec_s, $min_s, $hour_s ) = ( localtime($start) )[ 0 .. 2 ];
my $now = time;
( $sec_n, $min_n, $hour_n ) = ( localtime($now) )[ 0 .. 2 ];
my $alltime=time-$start;
( $sec_a, $min_a, $hour_a ) = ( localtime($alltime) )[ 0 .. 2 ];
$hour_a -= 8;
printf ("start:[ %02d:%02d:%02d ]\n",$hour_s,$min_s,$sec_s );
printf ("now:[ %02d:%02d:%02d ]\n", $hour_n, $min_n,$sec_n);
printf ("total:[ %02d:%02d:%02d ]\n", $hour_a, $min_a,$sec_a);
1;