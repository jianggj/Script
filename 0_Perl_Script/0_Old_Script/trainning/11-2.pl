#!/usr/bin/perl -w

my %hHash;

foreach(@ARGV)
{
	unless(-e $_)
	{print "ファイル[$_]が存在しません\n";next;}
	else
	{
		my $iDays= -M $_;
		$hHash1{$iDays}=$_;
		$hHash2{$_}=-A $_;
		$hHash3{$_}=-C $_;
	}


@aKey=sort keys %hHash1;
$iTimeM= $aKey[$#aKey];
$sName=$hHash1{$iTimeM};
$iTimeA=$hHash2{$sName};
$iTimeC=$hHash3{$sName};

}
print "ファイル:【$sName】,修正時間：[$iTimeM],-A:$iTimeA,-C:$iTimeC \n";

