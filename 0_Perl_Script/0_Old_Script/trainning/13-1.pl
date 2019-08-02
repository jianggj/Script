#!/usr/bin/perl -w

chomp(@aNum=<STDIN>);

my @aN=sort {$a<=>$b} @aNum;
print "-----" x 2 ,"\n";
foreach(@aN)
{
	printf "%10s\n",$_;
}
print "-----" x 2 ,"\n";

