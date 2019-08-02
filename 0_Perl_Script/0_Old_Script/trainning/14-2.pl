#!/usr/bin/perl -w

open STDOUT,">>"."14-2.ls.out";
open STDERR,">>14-2.err";
print STDOUT "----------------------\n";
@t= system 'cd;ls -l';
print STDOUT "@t";
print STDOUT "----------------------\n";
close STDOUT;
close STDERR;

