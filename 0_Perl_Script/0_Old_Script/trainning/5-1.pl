#!/usr/bin/perl

my $iNum=@ARGV;
my @aFile=@ARGV;

for($i=0;$i<$iNum;$i++)
{
	@ARGV=shift(@aFile);
	print reverse<>;
	@ARGV=qw();
}

