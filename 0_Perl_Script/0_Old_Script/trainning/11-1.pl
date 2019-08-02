#!/usr/bin/perl

my @aProperty=qw();

foreach(@ARGV)
{
	if(-e $_)
	{
		if(-r $_){push(@aProperty,"読み取り可能") ;}else{push(@aProperty,"読み取り不可") ;}
		if(-w $_){push(@aProperty,"書き込み可能");}else{push(@aProperty,"書き込み不可") ;}
		if(-x $_){push(@aProperty,"実行可能");}else{push(@aProperty,"実行不可") ;}
	}else
	{
		print "ファイルが存在しません\n";next;
	}
	my $sPro=join"--",@aProperty;
	print "ファイル[ $_ ] 特性が : $sPro\n";
	@aProperty=qw();
}
