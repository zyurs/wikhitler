#!/usr/bin/perl
use warnings;
use strict;

use LWP::Simple;

##########################
#                        #
# Variables declarations #
#                        #
##########################

# The page where to start searching
my $start_page = $ARGV[0];
# Wikipedia site (depends of country)
my ($wikipedia) = $start_page =~ /(.*)\/wiki\/.*/;
# The article on wikipedia to search
my $goal_article = "/wiki/Adolf_Hitler";
# The link to the article to search
my $goal_page = $wikipedia.$goal_article;
# Maximal deep of search to avoid infinity search
my $max_deep = 3;
# Number of visited pages
my $page_count = 0;
# Array where to save one solution
my @tres = ();
# Associative array where save all solutions found
my @paths = ();


#########################################################################
#                                                                       #
# Recursive function to search a page through all links in a given page #
# Parameters :                                                          #
#              $current_page : the page to treat                        #
#              $deep : actual deep of the page                          #
#                                                                       #
#########################################################################
sub search_page {
	# Retrieval function arguments, $next_page is the page to analyse and $deep the actual deep of this page
	my($current_page, $deep) = @_;
	$page_count = $page_count + 1;
	print "Deep $deep page n°$page_count searching at $current_page\n";

	# Retrieval the page html code with http get request in $res variable
	my $res = get($current_page);
	# Associative array of all links in the page
	my %links = ();
	# substract the html code for better target the article 
	($res) = $res =~ /(id="mw-content-text".*id="mw-navigation")/s;
	# Boolean variable, true if the goal page is found in current page
	my $find = 0;

	#
	# Search for goal page in current page
	#
	if ($res =~ /$goal_article/){
		$find = 1;
		# Save result in $tres array
		$tres[$deep+1] = article_name($goal_page);

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
	# If the goal page is not found, search deeper
	#
	if (!$find && $deep < $max_deep) {

		#
		# Search all links in the page
		#
		while ($res =~ /href="(\/wiki\/.*?)"/g) {
			my $val = $1;
	
			# Delete the paragraphe part on the link
			if ($val =~ /(.*)#/) {
				($val) = $val =~ /(.*)#/;
			}
	
			# Select commons pages only and add them to the associative array
			if ($val !~ /:/) {
				$links{$val} = ();
			}
		}

		foreach my $keys (keys(%links)) {
			$tres[$deep+1] = article_name($keys);

			if (search_page($wikipedia.$keys, ($deep+1))) {
				last;
			}
		}
	}
	return $find;
	
}

###################################################
#                                                 #
# Extract the article name from a link            #
# Parameter :                                     #
# 		$article_link : the link to treat #
#                                                 #
###################################################
sub article_name {
	my ($article_link) = @_;
	($article_link) = $article_link =~ /\/wiki\/(.*$)/s;
	return $article_link;
}

#############
#           #
# Treatment #
#           #
#############

# Initialization of tres array with the start page
($tres[0]) = article_name($start_page); # =~ /\/wiki\/(.*$)/s;
# start the search begining at the start page
search_page($start_page, 0); 

#
# Print the result(s)
#
print "\n--------------------\n";
# The number of link for the path found
my $step = 0;

foreach my $link (@{$paths[0]}) {
	print "$step : $link\n";
	$step = $step + 1;
}

print "\n";
