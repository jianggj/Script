#!/usr/bin/perl -w

print "文字列を入力してください:\n";
chomp(@aStr=<STDIN>);

my %hHash;

foreach(@aStr)
{
	if(exists $hHash{$_})
	{	$hHash{$_}++;}
	else
	{	$hHash{$_}=1;}
}

foreach $key (sort keys %hHash)
{
	print "$key => $hHash{$key}\n";
}
