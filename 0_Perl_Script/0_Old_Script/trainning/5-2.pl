#!/usr/bin/perl

chomp(@sStr=<STDIN>);
print "12345678901234567890\n";
foreach(@sStr)
{
	printf "%20s\n",$_;
}
