#!/usr/bin/perl

use vars qw/$libpath/;
use FindBin qw($Bin);
BEGIN { $libpath="$Bin" };
use lib "$libpath";
use lib "$libpath/../lib";

use LWP::Simple;
$maindir = $Bin; # "/home/tikhonov/tools/illusion4digital";
$indir = "$maindir/in";
mkdir $indir unless (-e $indir);
$outdir = "$maindir/out";
mkdir $outdir unless (-e $outdir);
use Getopt::Std;
 
# declare the perl command line flags/options we want to allow
my %options=();
getopts("hf:H::m:u:", \%options);
 
# test for the existence of the options on the command line.
# in a normal program you'd do more than just print these.
$url = $options{u} if ($options{u});
$urls{$url}++ if ($url);
$file = $options{f} if ($options{f});
$htmlfile = $options{H} if ($options{H});

if ($htmlfile)
{
    %urls = fromHTML($htmlfile);
}

$file = 'default' unless ($file);

foreach $thisurl (keys %urls)
{
   $url = $thisurl;
}

if ($url=~/^(htt\w+\:\/\/\S+?)\//)
{
   $root = $1;
   if ($url=~/^(htt\w+\:\/\/\S+)\//)
   {
	$fullurl = $1; 
   }
}

print "Full $fullurl\n";
if ($fullurl=~/$root\/(.+?)$/)
{
    $tmpdir = $1;
    $tmpdir=~s/\W+/\_/g;
    $tmpdir=~s/^\///g;
    $tmpdir=~s/\/$//g;
    print "DIR $dir\n";
    $dir = "$indir/$tmpdir";
    mkdir $dir unless (-e $dir);
}

 
$content = get($url);
$content=~s/\r|\n//g;
my @urls = split(/href\=/, $content);
foreach $url (@urls)
{
   $url=~s/^\"|\^//g;
   if ($url=~/^(\S+?)\">(.+?)<\/a>/sxi)
   {
	$uri = $1;
	$title = $2;
	my $locallink;

	$locallink = 1 if ($uri=~/http/ && $uri=~/$root/);
	$locallink = 2 if ($uri!~/http/);

	if ($locallink)
	{
	   if ($locallink eq 2)
	   {
		$uri=~s/^\///g;
		$uri = $fullurl."/$uri";
	   }

	   unless ($urls{$uri})
	   {
		push(@mainurls, $uri);
	   }
	   $urls{$uri} = $title;

           print "$dir $uri $title\n" if ($DEBUG);
	};
   };
}

@mainurls = ($url);
foreach $url (@mainurls)
{
    my $file = $url;
    if ($file=~/^.+\/(\S+)$/)
    {
	$file = $1;
	$file=~s/\W+/_/g;
	$file=~s/\.html$//g;
	$file=~s/\.htm$//g;
	$file=~s/\/$//g;
	print "$file.pdf\n";
   	$cmd = `/media/ext2/node_modules/.bin/phantomjs /media/ext2/phantomjs/examples/rasterize.js "$url" "$outdir/$file.pdf" A4`;
 	push(@files, "$outdir/$file.pdf");
        print "URL $url $dir/$file.pdf\n" if ($DEBUG);
    }
}

foreach $file (@files)
{
   $outline.="$file ";
}
$finaldir="$outdir/$tmpdir";

$finalcmd = "/usr/bin/pdftk $outline cat output $finaldir.pdf";
$run = `$finalcmd;`; # -rf $dir`;
if (-e "$finaldir.pdf")
{
   print "$finalcmd\n";
   $sendmail = `$Bin/sendfile.py \"$finaldir.pdf\"`;
};

sub fromHTML
{
   ($filename, $DEBUG) = @_;
   open(file, $filename);
   @content = <file>;
   close(file);

   my $active;
   foreach $str (@content)
   {
	if ($str=~/Content\-Type\:\s+text\/plain\;/)
	{
	    $active++;
	} 
	elsif ($str=~/Content\-Type\:\s+text\/html/)
	{
	    $active = 0;
	}
	if ($active)
	{
	    $str=~s/\r|\n//g;
	    if ($str=~/(htt\w+\:\/\/\S+)/)
	    {
		$url = $1;
	 	$urls{$url}++;
	    }
	}
   }

   return %urls;
}