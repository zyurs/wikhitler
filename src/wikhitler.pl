#!/usr/bin/perl
use warnings;
use strict;

use LWP::Simple;

# Variables declarations
my $start_page = $ARGV[0];
my $wikipedia = 'https://fr.wikipedia.org';
my $goal_article = "/wiki/Adolf_Hitler";
my $goal_page = $wikipedia.$goal_article;
my $max_deep = 3;
my $page_count = 0;
my @tres = ();
my @paths = ();

$tres[0] = $start_page;

# Recursive function to search a page through all links
sub search_hitler {
	# Retrieval function arguments, $next_page is the page to analyse and $deep the actual deep of this page
	my($current_page, $deep) = @_;
	$page_count = $page_count + 1;
	print "Deep $deep page n°$page_count searching at $current_page\n";

	#
	# Retrieval the page html code with http get request in $res variable
	#
	my $res = get($current_page);
	# Associative array of all links in the page
	my %links = ();
	# substract the string  
	($res) = $res =~ /(id="mw-content-text".*id="mw-navigation")/s;

	# Boolean variable, true if the goal page is found in current page
	my $find = 0;
	# Search for goal page in current page
	if ($res =~ /$goal_article/){
		$find = 1;
		# Save result in $tres array
		$tres[$deep+1] = $goal_page;

		# Delete old results in $tres tab
		for my $i ($deep+1 .. $#tres-1) {
			pop(@tres);
		}

		# Put result tab in associative array to save this path to goal page
		unshift(@paths, undef);

		for my $i (0 .. $#tres) {
			$paths[0][$i] = $tres[$i];
		}

		# Change max deep to currend deep -1
		$max_deep = ($deep-1);
		# Print results
		print "Find page at deep: ".($deep+1)."\n";

		foreach my $a (@tres) {
			print $a." ";
		}

		print "\n";

	}
	
	#
	# Search all links in the page
	#
	while ($res =~ /href="(\/wiki\/.*?)"/g) {
		my $val = $1;

		# Delete the paragraphe part on the link
		if ($val =~ /(.*)#/) {
			$val = $val =~ /(.*)#?/;
		}

		# Select commons pages only and add them to the associative array
		if ($val !~ /:/) {
			$links{$val} = ();
		}
	}
	
	#
	# If goal page is not found, search deeper
	#
	if (!$find && $deep < $max_deep) {

		foreach my $keys (keys(%links)) {
			$tres[$deep+1] = $keys;

			if (search_hitler($wikipedia.$keys, ($deep+1))) {
				last;
			}
		}
	}
	return $find;
	
}

search_hitler($start_page, 0); 
print "\n--------------------\n";
my $step = 0;

foreach my $link (@{$paths[0]}) {
	my ($l) = $link =~ /\/wiki\/(.*$)/s;
	print "$step : $l\n";
	$step = $step + 1;
}

print "\n";
