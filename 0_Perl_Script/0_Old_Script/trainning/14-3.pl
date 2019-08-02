#!/usr/bin/perl -w

my $date= `date`;

my @date=split /\s+/,$date;
print "今天是：".$date[3]."\n";

if($date[3] eq "日曜日"|$date[3] eq "土曜日")
{print "go play!\n";}
else{print "go to work!\n";}



