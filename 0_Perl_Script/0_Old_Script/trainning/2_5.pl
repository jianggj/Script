#!/usr/bin/perl -w

print "文字列を入力してください:\n";
chomp($sStr=<STDIN>);
$sStr .= "\n";

print "最初の数字を入力してください:\n";
$iNum=<STDIN>;

print "実行した結果:\n";

print $sStr x $iNum;
