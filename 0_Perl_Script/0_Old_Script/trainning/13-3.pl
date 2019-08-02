#!/usr/bin/perl -w

print "输入原字符串：\n";
chomp($sStr=<STDIN>);

print "输入要查找的子字符串：\n";
chomp($sChild=<STDIN>);
print "-------------------------\n";

my $iOld=0;

if(index($sStr,$sChild)==-1)
{ print "要查找的子字符串不存在！\n";}
else{
while(!(index($sStr,$sChild)==-1))
{
	$iPosition=index($sStr,$sChild);
	push(@aPnum,$iPosition+$iOld);
	$sStr=substr($sStr,$iPosition+1,);
	$iOld+=$iPosition+1;

}
foreach(@aPnum)
{
	$_++;
    print "出现的位置在第$_ 个字符。\n";
}
}
