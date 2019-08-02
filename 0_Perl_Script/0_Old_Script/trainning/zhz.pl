#!/usr/bin/perl -w

$t="abc123 def.mn.456";

if($t =~ /((\w+?)(\d*)\s)(\w*\.(\w+)\.(\d*))/i)
{
print "\$1 is $1\n";
print "\$2 is $2\n";
print "\$3 is $3\n";
print "\$4 is $4\n";
print "\$5 is $5\n";
print "\$6 is $6\n";
}

$p="abc123";
if($p =~ /\w+?/)
{print $&;}
