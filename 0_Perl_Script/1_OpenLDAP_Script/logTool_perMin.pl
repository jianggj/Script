#!/usr/bin/perl -w
######################################################################
#FileName:logTool_perMin.pl
#Description:指定されたファイルに対して、LDAPログ（256）を解析する。
#            1分間で結果を出力する。
######################################################################

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use Encode;
use File::Path;
use Date::Manip;

#===========変数定義 Start===========
# 本ツールの格納箇所
my $TOOL_DIR = dirname(__FILE__);
# ファイルの格納箇所パス（ファイル名）
my $LOG_FILE;
#時間
my $year;
my $mon;
my $mday;
my $hour;
my $min;
my $sec;

#統計結果1:重大エラーの統計
my $all_err_key="\"regex\" style implies \"expand\" modifier|: err|alock package is unstable|already|attr val requires a single attribute|bad|ber_get_int returns|ber_peek_tag returns|bogus referral in context|can only be global|cannot|can't|contains non-numeric|could not|database already in use|database already shadowed|database must have suffix|defaultSearchBase line must appear|deferring|deprecated|disabled|does not|duplicate mapping found|duplicate URI in|empty|entry already exists|entry exists|errno|Error|failed|failure|has an expired password|has changed|has no|illegal|inappropriate|incompatible|incomplete|inconsistent|incorrect|init called twice|invalid|is always|is deprecated|is expired|is not|is subclass of alias|is subclass of referral|is volatile|issuer|malformed message|meaningless|mismatch|missing|more than|more than once|more than one|multiple|must be|must contain attribute|need|needs|newSuperior requires LDAPv3|no|not|nothing to destroy|NULL|obsolete|only allowed|only meaningful|only one attribute allowed in URI|only one to clause allowed in access line|out of memory|out of range|premature EOL|register_at: AttributeType|regular file expected|retry|retrying|rewriteEngine needs 'state'|should|silently dropped modification|skipped|slapd gentle shutdown|suffix already served by this backend|timeout|to clause required before by clause in access line|too great|too large|too long|too long for column|too low|too many|too small|unable|unclean|undefined mode|undocumented|unknown|unlocked certificate for certificate|unparseable|unrecognized|unsupported|warning|was ignored by|will be discarded|without|would call self|deferring operation";
my @all_err_key=();
my $KeyCount=0;
#統計結果2:通常なエラーの統計
my $all_err_count=0;
my %hErrCon;
my %hErr_count;
#統計結果3:接続状態関連の統計
my $all_con=0; #接続数
my $start_con=0; #開始あり、終了なし
my $close_con=0;#開始あり、終了あり
my $noS_noC=0;#開始なし、終了なし
my $noS_yesC=0;#開始なし、終了あり
#統計結果4:エントリOPの統計
my $add_count=0;
my $mod_count=0;
my $search_count=0;
my $del_count=0;
my $pwdmod_count=0;
#統計結果5:RESULTなしの統計
my $accept_only=0;
my %h_accept_only;
my $close_no=0;
my %h_close_no;
my $bind_no_result=0;
my %h_bind_no_result;
my $srch_no_result=0;
my %h_srch_no_result;
my $add_no_result=0;
my %h_add_no_result;
my $mod_no_result=0;
my %h_mod_no_result;
my $del_no_result=0;
my %h_del_no_result;
my $pwmod_no_result=0;
my %h_pwmod_no_result;
#格納HASH
my %hConns;
my %hStartConn;  #開始あり、終了なし
my %hCloseConn;  #終了あり
my %hOther;      #開始なし、終了なし

#ァイルを読み込み用
my @lines;

#接続CLASS
my %hConnClass;
#%hConnClass：
#%hConnClass{$conn no}=(
#     {"ACCEPT"} => 1/0;   開始:あり、なし
#     {"CLOSED"} => 1/0;  終了あり、なし
#     {"UNBIND"} => 1/0;   UNBINDかどうか
#     {"UNBIND_OP_NO"};   UNBINDのOP番号
#     {"OP_NO"} => "0|1|...|9999";  op数
#     {$op no}=>(                         OPのhash
#                            {"OP"} => ADD,MOD...
#                             {"OPR"}=>1/0  op result
#                                  );
#);

#LDAP戻りコードの意味（OpenLDAP2.4-Admin-Guide.pdf）
my %hResultCodes=(
    1 => "1:operationsError",
	2 => "2:protocolError ",
	3 => "3:timeLimitExceeded ",
	4 => "4:sizeLimitExceeded ",
	5 => "5:compareFalse ",	#Non-Error Result Code
	6 => "6:compareTrue ",	#Non-Error Result Code
	7 => "7:authMethodNotSupported ",
	8 => "8:strongerAuthRequired ",
	10 => "10:referral ",	#Non-Error Result Code
	11 => "11:adminLimitExceeded ",
	12 => "12:unavailableCriticalExtension ",
	13 => "13:confidentialityRequired ",
	14 => "14:saslBindInProgress ",	#Non-Error Result Code
	16 => "16:noSuchAttribute ",
	17 => "17:undefinedAttributeType ",
	18 => "18:inappropriateMatching ",
	19 => "19:constraintViolation ",
	20 => "20:attributeOrValueExists ",
	21 => "21:invalidAttributeSyntax ",
	32 => "32:noSuchObject ",
	33 => "33:aliasProblem ",
	34 => "34:invalidDNSyntax ",
	36 => "36:aliasDereferencingProblem ",
	48 => "48:inappropriateAuthentication ",
	49 => "49:invalidCredentials ",
	50 => "50:insufficientAccessRights ",
	51 => "51:busy ",
	52 => "52:unavailable ",
	53 => "53:unwillingToPerform ",
	54 => "54:loopDetect ",
	64 => "64:namingViolation ",
	65 => "65:objectClassViolation ",
	66 => "66:notAllowedOnNonLeaf ",
	67 => "67:notAllowedOnRDN ",
	68 => "68:entryAlreadyExists ",
	69 => "69:objectClassModsProhibited ",
	71 => "71:affectsMultipleDSAs ",
	80 => "80:other "
);
#初次の時間フラッグ
my $min_flag=0;
#開始の時間
my $min_start=0;
#1分間に、開始と終了時間（ログ中記載と同じ）
my $line_start_min="";
my $line_end_min="";
#===========変数定義 END===========

#------------------------------前処理 --------------------------------
#エラーのキーワード
@all_err_key = split /\|/,$all_err_key;
$all_err_key =~s/\|/\\b\|\\b/g;
$all_err_key =~ s/^(.*)/\\b$1\\b/g;

print "==========Programe START! ==========\n";

#パラメータ(解析ログの格納箇所)を取得する
if(@ARGV == 1)
{
	$LOG_FILE = shift;
}elsif(@ARGV == 0){
	die "ログファイルをご指定ください！\n**********Programe EXIT**********\n";
}else{
	die "ログファイル指定エラー！\n**********Programe EXIT**********\n";
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

	#ログ終了日時取得
	my $lastline=$lines[-1];
	my @lastlines=split /\s+/ , $lastline;
	my ($fmon,$fday,$ftime)=@lastlines[0,1,2];
	my $FinishTime=$fmon." ".$fday." ".$ftime;
	
	printf(OUT_FILE "\nログの時間：%s 〜 %s\n",$StartTime,$FinishTime);
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
	#この行の時間取得
	my @line_time=split /\s+/ , $splitLine;
    my ($line_mon,$line_day,$line_time)=@line_time[0,1,2];
	my @time_tmp=split /\:/ , $line_time;
	my $time_tmp_00=$time_tmp[0].":".$time_tmp[1].":"."00";
	my $line_date=$line_mon." ".$line_day." ".$time_tmp_00;
	if($min_flag == 0)
	{
	    $min_start = &UnixDate($line_date, "%s");
		$line_start_min = $line_mon." ".$line_day." ".$time_tmp[0].":".$time_tmp[1].":".$time_tmp[2];
	    $min_flag = 1;
	}elsif($min_flag == 1)
	{
	    $line_end_min = $line_mon." ".$line_day." ".$time_tmp[0].":".$time_tmp[1].":".$time_tmp[2]; 
	    my $line_time = &UnixDate($line_date, "%s");
	    if(($line_time - $min_start >= 60 )||$lines[-1] eq $splitLine)
	    {
	        &CountFun();
			&PrintFun($line_start_min,$line_end_min);
	        {
	            #変数初期化
	            %hConns        = ();    #接続番号HASH
	            %hStartConn    = ();    #開始あり終了なしHASH
	            %hConnClass    = ();    #接続CLASS HASH
	            %hCloseConn    = ();    #終了あり HASH
	            %hOther        = ();    #開始なし終了なしHASH
	            %hErrCon       = ();    #通常なエラーHASH
	            %hErr_count    = ();    #通常なエラー統計HASH

	            $KeyCount      = 0;     #重大エラー統計
	            $start_con     = 0;     #開始あり終了なし数
	            $all_con       = 0;     #接続数
	            $close_con     = 0;     #開始あり終了あり数
	            $noS_noC       = 0;     #開始なし終了なし数
	            $noS_yesC      = 0;     #開始なし終了あり数
	            $all_err_count = 0;     #通常なエラー統計数 
	        }
			{
			    #時間制御初期化
				#  $min_flag       = 0;
				$min_start      = $line_time;
				$line_start_min = $line_end_min;
				$line_end_min   = "";
			}
	    }
	}
	#接続番号取得
	if($splitLine =~ /(?:.*)conn=(\d+)(?:.*)/i)
	{
	    $con_code =$1;
	    $hConns{$con_code}=1;
	}elsif($splitLine =~ /$all_err_key/i)
	{
		#統計結果1:重大エラーの統計
		foreach my $key(@all_err_key)
		{
			if($splitLine =~ /\b$key\b/i)
			{
				$KeyCount++;
			}
		}
		next;
	}else{
		next;
	}

	if($splitLine =~ /(.*)ACCEPT(.*)/i)
	{#開始を一致
		
		$hStartConn{$con_code}=1;
		$start_con++;
		$all_con++;
		#ConnClass初期化
		$hConnClass{$con_code}{"ACCEPT"} = 1;
		$hConnClass{$con_code}{"CLOSED"} = 0;
		$hConnClass{$con_code}{"UNBIND"} = 0;
		$hConnClass{$con_code}{"UNBIND_OP_NO"} = -1;
		$hConnClass{$con_code}{"OP_NO"} = "";
		
	}elsif($splitLine =~ /(.*)fd=(\d+)(\s*)closed(.*)/i)
	{#終了を一致
		
		$hCloseConn{$con_code}=1;
		$hConnClass{$con_code}{"CLOSED"} = 1;
		if(exists $hStartConn{$con_code})
		{#開始ありの場合、統計のみ、内容を無視
			delete $hStartConn{$con_code};
			$close_con++;
			$start_con--;
		}elsif(exists $hOther{$con_code})
		{
			$noS_yesC++;
			$noS_noC--;
		}else{
         #開始なしの場合
			    $all_con++;
			    $noS_yesC++;
			    #ConnClass初期化
				$hConnClass{$con_code}{"ACCEPT"} = 0;
				$hConnClass{$con_code}{"UNBIND"} = 0;
				$hConnClass{$con_code}{"UNBIND_OP_NO"} = -1;
				$hConnClass{$con_code}{"OP_NO"} = "";
		}
		$hConnClass{$con_code}{"CLOSED"}=1;
	}else{#一般の場合
		unless((exists $hStartConn{$con_code})||(exists $hCloseConn{$con_code} )||(exists $hOther{$con_code}))
		{
			$hOther{$con_code} = 1;
			$all_con++; 
			$noS_noC++;
			#ConnClass初期化
			$hConnClass{$con_code}{"ACCEPT"} = 0;
			$hConnClass{$con_code}{"CLOSED"} = 0;
			$hConnClass{$con_code}{"UNBIND"} = 0;
			$hConnClass{$con_code}{"UNBIND_OP_NO"} = -1;
			$hConnClass{$con_code}{"OP_NO"} = "";
		}

		{
			#OP取得
			if($splitLine =~/\bop=(\d+) (\S+).*/i)
			{
				$op_code=$1;
				$op=$2;
				if($op eq "UNBIND")
				{
					$hConnClass{$con_code}{"UNBIND"} = 1;
					$hConnClass{$con_code}{"UNBIND_OP_NO"} = $op_code;
					next;
				}
				if(($op eq "SEARCH" )&&($splitLine =~/.*conn=$con_code op=$op_code .*\btag=(\d+).*/i))
				{
					#SEARCH RESULT tag=101
					$hConnClass{$con_code}{$op_code}{"OPR"} = 1 if $1 == 101;
					next;
				}
				#OPがRESULTの場合、該当接続のOPRフラグを設定
				if($op eq "RESULT")
				{
					$hConnClass{$con_code}{$op_code}{"OPR"} = 1 ;
					next;
				}
				#該当接続のOP数を追加
				if($hConnClass{$con_code}{"OP_NO"} eq "")
				{
					$hConnClass{$con_code}{"OP_NO"} ="".$op_code;
				}else{
					unless($hConnClass{$con_code}{"OP_NO"} =~ /\b$op_code\b/i){
					$hConnClass{$con_code}{"OP_NO"} .="|".$op_code;
					}
				}
				#該当接続のclassを設定
				$hConnClass{$con_code}{$op_code}{"OP"} =$op;
				$hConnClass{$con_code}{$op_code}{"OPR"} = 0;
			}
		}
		#統計結果2:通常なエラーの統計
		if($splitLine =~ /(?:.*)err=(\d+)(?:.*)/i)
		{
			#エラーコード取得
			my $err_code = $1;
			#対象外コード
			if($err_code !=0&&$err_code!=5&&$err_code!=6&&$err_code!=10&&$err_code!=14)
			{
				if(exists $hErrCon{$err_code}{$con_code})
				{
					$hErrCon{$err_code}{$con_code} .="|".$op_code;
				}else{
					$hErrCon{$err_code}{$con_code}  = "".$op_code;
				}
				$all_err_count++;
				$hErr_count{$err_code}++;
			}
		}
	}
}#行処理終了

#終了
print "処理完了\n";
printf(OUT_FILE "\n%s %s %s\n","<-"x17," ここまで ","->"x17);
&outputclose();
print "==========Programe FINISH!==========\n";
#------------------------------関 数--------------------------------

#*************************************************************
#Function Name:CountFun()
#Description:統計結果集計
#*************************************************************

sub CountFun() {
    foreach my $con(sort{$a<=>$b} keys %hConns)
    {
    	my $op_no=$hConnClass{$con}{"OP_NO"};
    	my @ops= split /\|/ , $op_no;
    	foreach my $opc (@ops)
    	{
    		my $op = $hConnClass{$con}{$opc}{"OP"}; 
    		if($op eq "BIND"  && $hConnClass{$con}{$opc}{"OPR"} ==0)
    		{
    			$bind_no_result++;
    			if(exists $h_bind_no_result{$con})
    			{
    				$h_bind_no_result{$con} .= "|".$opc;
    			}else{
    				$h_bind_no_result{$con} = "".$opc;
    			}
    			next;
    		}
    		#4:エントリOPの統計
    		if($op eq "ADD")
    		{
    			$add_count++;
    			if($hConnClass{$con}{$opc}{"OPR"} ==0)
    			{
    				$add_no_result++;
    				if(exists $h_add_no_result{$con})
    				{
    					$h_add_no_result{$con} .= "|".$opc;
    				}else{
    					$h_add_no_result{$con} = "".$opc;
    				}
    			}
    		}elsif($op eq "MOD")
    		{
    			$mod_count++;
    			if($hConnClass{$con}{$opc}{"OPR"} ==0)
    			{
    				$mod_no_result++;
    				if(exists $h_mod_no_result{$con})
    				{
    					$h_mod_no_result{$con} .= "|".$opc;
    				}else{
    					$h_mod_no_result{$con} = "".$opc;
    				}
    			}
    		}elsif($op eq "SRCH")
    		{
    			$search_count++;
    			if($hConnClass{$con}{$opc}{"OPR"} ==0)
    			{
    				$srch_no_result++;
    				if(exists $h_srch_no_result{$con})
    				{
    					$h_srch_no_result{$con} .= "|".$opc;
    				}else{
    					$h_srch_no_result{$con} = "".$opc;
    				}
    			}
    		}elsif($op eq "DEL")
    		{
    			$del_count++;
    			if($hConnClass{$con}{$opc}{"OPR"} ==0)
    			{
    				$del_no_result++;
    				if(exists $h_del_no_result{$con})
    				{
    					$h_del_no_result{$con} .= "|".$opc;
    				}else{
    					$h_del_no_result{$con} = "".$opc;
    				}
    			}
    		}elsif($op eq "PASSMOD")
    		{
    			$pwdmod_count++;
    			if($hConnClass{$con}{$opc}{"OPR"} ==0)
    			{
    				$pwmod_no_result++;
    				if(exists $h_pwmod_no_result{$con})
    				{
    					$h_pwmod_no_result{$con} .= "|".$opc;
    				}else{
    					$h_pwmod_no_result{$con} = "".$opc;
    				}
    			}
    		}
    	}
    	#5:RESULTなしの統計
    	if($hConnClass{$con}{"ACCEPT"} == 1 && $op_no eq "" && $hConnClass{$con}{"CLOSED"} == 0)
    	{
    		$accept_only++;
    		$h_accept_only{$con}= "-1";
    	}
    	if($hConnClass{$con}{"UNBIND"} == 1 && $hConnClass{$con}{"CLOSED"} == 0)
    	{
    		$close_no++;
    		if($hConnClass{$con}{"UNBIND_OP_NO"} == -1||$hConnClass{$con}{"UNBIND_OP_NO"} eq "")
    		{
    			die "接続[".$con."]のUNBINDのOP番号取得エラー！\n";
    		}else{
    			$h_close_no{$con}=1;
    		}
    	}
    }
}
#*************************************************************
#Function Name : PrintFun()
#parameter     : start_time 開始の分
#                end_time   終了の分
#Description   : 統計結果ファイルに出力
#*************************************************************
sub PrintFun() {
	my($start_time, $end_time) = @_;
	printf(OUT_FILE "\n■ [%s]から、[%s]前に統計：\n",$start_time,$end_time);
    printf(OUT_FILE "\n%s%s%s\n","="x34,"統計結果一覧","="x34);
	#printf(OUT_FILE "【重大なエラー】%s：%6d\n","\t",$KeyCount);
	#printf(OUT_FILE "【通常なエラー】%s：%6d\n","\t",$all_err_count);
    printf(OUT_FILE "【接続数】%s：%6d\n","\t"x3,$all_con);
    printf(OUT_FILE " ACCEPTあり、CLOSEDあり数：	%6d",$close_con);
    printf(OUT_FILE "%sACCEPTあり、CLOSEDなし数：	%6d\n","\t"x3,$start_con);
    printf(OUT_FILE " ACCEPTなし、CLOSEDあり数：	%6d",$noS_yesC);
    printf(OUT_FILE "%sACCEPTなし、CLOSEDなし数：	%6d\n","\t"x3,$noS_noC);
    printf(OUT_FILE "【種類別リクエスト数】\n");
    printf(OUT_FILE " SRCH数%s：%6d\n","\t"x4,$search_count);
    printf(OUT_FILE " MOD数%s：%6d\n","\t"x4,$mod_count);
    printf(OUT_FILE " ADD数%s：%6d\n","\t"x4,$add_count);
    printf(OUT_FILE " DEL数%s：%6d\n","\t"x4,$del_count);
    printf(OUT_FILE " PASSMOD数%s：%6d\n","\t"x3,$pwdmod_count);
    printf(OUT_FILE "%s\n","*"x80); 
    {
    	printf(OUT_FILE "【重大なエラー】%s：%6d\n","\t",$KeyCount);
	    #統計結果2:通常なエラーの統計
		printf(OUT_FILE "【通常なエラー】%s：%6d\n","\t",$all_err_count);
    	my $c_t=0;
		#printf(OUT_FILE "<通常なエラー(err=0、5、6、10、14以外)の統計>\n");
		#printf(OUT_FILE "【総計】	：%6d\n",$all_err_count);
    	last if $all_err_count == 0;
    	foreach my $ecode(keys %hErr_count)
    	{
    		if(exists $hResultCodes{$ecode})
    		{
    			printf(OUT_FILE "  <エラーコード%s>の数:	%4d\n",$hResultCodes{$ecode},$hErr_count{$ecode});
    		}else{
    			printf(OUT_FILE "  <エラーコード%s>の数:	%4d\n",$ecode,$hErr_count{$ecode});
    		}
    	}
    }
    printf(OUT_FILE "%s\n","*"x80); 
    {
    	#統計結果3:異常接続統計を出力
    	printf(OUT_FILE "<異常可能な接続>\n");
    	my $count_tmp = $accept_only+$close_no+
    									$bind_no_result+$srch_no_result+
    									$add_no_result+$mod_no_result+
    									$del_no_result+$pwmod_no_result;
    	printf(OUT_FILE "【総計】:%6d\n",$count_tmp);
    	printf(OUT_FILE "【ACCEPTあり、後は何も操作がなし】%s：%6d\n","\t"x4,$accept_only);
    	printf(OUT_FILE "【BINDあり、RESULTがなし】%s：%6d\n","\t"x5,$bind_no_result);
    	printf(OUT_FILE "【SRCHあり、RESULTなし】%s：%6d\n","\t"x5,$srch_no_result);
    	printf(OUT_FILE "【ADDあり、RESULTなし】%s：%6d\n","\t"x6,$add_no_result);
    	printf(OUT_FILE "【MODあり、RESULTなし】%s：%6d\n","\t"x6,$mod_no_result);
    	printf(OUT_FILE "【DELあり、RESULTなし】%s：%6d\n","\t"x6,$del_no_result);
    	printf(OUT_FILE "【PASSMODあり、RESULTなし】%s：%6d\n","\t"x5,$pwmod_no_result);
    	printf(OUT_FILE "【UNBINDあり、CLOSEDなし】%s：%6d\n","\t"x5,$close_no);
    
    	last if $count_tmp ==0;
    }
	printf(OUT_FILE "%s\n","="x80);
}

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
