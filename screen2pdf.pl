#!/usr/bin/perl

use vars qw/$libpath/;
use FindBin qw($Bin);
BEGIN { $libpath="$Bin" };
use lib "$libpath";
use lib "$libpath/../lib";

%config = readconfig($Bin);
use LWP::Simple;
$maindir = $config{dir}; 
$indir = "$maindir/in";
mkdir $indir unless (-e $indir);
$outdir = "$maindir/out";
mkdir $outdir unless (-e $outdir);
use Getopt::Std;
 
# declare the perl command line flags/options we want to allow
my %options=();
getopts("hf:H:m:u:", \%options);
 
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
   print "$url\n";

   if ($url=~/^(htt\w+\:\/\/\S+?)\//)
   {
      $root = $1;
      if ($url=~/^(htt\w+\:\/\/\S+)\//)
      {
	  $fullurl = $1; 
	  $weburls{$url}{root} = $root;
	  $weburls{$url}{fullurl} = $fullurl;

	  if ($fullurl=~/$root\/(.+?)$/)
	  {
    	     $tmpdir = $1;
    	     $tmpdir=~s/\W+/\_/g;
    	     $tmpdir=~s/^\///g;
    	     $tmpdir=~s/\/$//g;
    	     print "DIR $tmpdir\n";
    	     $dir = "$indir/$tmpdir";
    	     mkdir $dir unless (-e $dir);
	     $weburls{$url}{dir} = $dir;
	 }
      }
   }
}


$content = `$config{wget} -q \"$fullurl\" -O -`;  get($fullurl);
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

@mainurls = ($fullurl);
foreach $url (sort keys %weburls)
{
    my $file = $url;
    if ($file=~/^.+\/(\S+)$/)
    {
	$file = $1;
	$file=~s/\W+/_/g;
	$file=~s/\.html$//g;
	$file=~s/\.htm$//g;
	$file=~s/\/$//g;
	print "$url Phantom: $outdir/$file.pdf\n";
   	$cmd = `$config{phantomjs} $config{rasterizejs} "$url" "$outdir/$file.pdf" A4`;
 	push(@files, "$outdir/$file.pdf");
        print "URL $url $dir/$file.pdf\n" if ($DEBUG);
    }
}

foreach $file (@files)
{
   $outline.="$file ";
}
$finaldir="$outdir/$tmpdir";
print "Outline $outline\n";

$finalcmd = "$config{pdftk} $outline cat output $finaldir.pdf";
$run = `$finalcmd;`; # -rf $dir`;
if (-e "$finaldir.pdf")
{
   print "$finalcmd\n";
   $to = $config{emailto};
   $sendmail = `$Bin/sendfile.py \"$to\" \"$finaldir.pdf\"`;
};

sub readconfig
{
    my ($path, $DEBUG) = @_;
    my %config;

    open(config, "$path/config/web2scan.conf");
    @config = <config>;
    close(config);

    foreach $str (@config)
    {
	# EMAIL_ACCOUNT = illusion4digital@gmail.com
	$str=~s/\r|\n//g;
	my ($name, $value) = split(/\s*\=\s*/, $str);
	$config{$name} = $value;
    }

    return %config;
}

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
