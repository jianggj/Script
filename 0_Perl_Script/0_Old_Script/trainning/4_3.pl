#!/usr/bin/perl

use strict;

sub total()
{
	my @total=@_;
	my $a=0;
	foreach (@total)
	{
		 $a+=$_;
	}
   return $a;
}


sub above_average()
{
	my @aNum=@_;
	my $iAverage=0;
	my $iTotal=0;
	my @aFinish=();
	my $iNum=$#aNum++;

	$iTotal=&total(@aNum);
	$iAverage=$iTotal/$iNum;

	foreach (@aNum)
	{
		if($_ >= $iAverage)
			{push(@aFinish,$_);}
			
	}
	return @aFinish;
	
}

my @fred=&above_average(1..10);
print "the fred is @fred.\n";

my @barney=&above_average(100,1..10);
print "the barney is @barney.\n";
