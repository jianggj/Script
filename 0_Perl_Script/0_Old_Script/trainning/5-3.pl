#!/usr/bin/perl

print "行幅を入力してください:\n";
chomp($iWidth=<STDIN>);
print "文字列を入力してください:\n";
chomp(@sStr=<STDIN>);

$iNum=$iWidth/10;
$iN2=($iWidth%10)/10;

$sRefer= "1234567890";


print "参照行:\n";
print $sRefer x $iNum;
printf "%${iN2}s\n",$sRefer;

foreach(@sStr)
{
	printf "%${iWidth}s\n",$_;
}
