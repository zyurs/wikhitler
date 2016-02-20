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
my $max_deep = 2;
# Number of visited pages
my $page_count = 0;
# Array where to save one solution
my @tres = ();
# Array where save all solutions found
my @paths = ();
# Blacklist file
my $blacklist_file = "blacklist.txt";
# Associative array with all blacklisted links
my %blacklisted_link = file_to_hash($blacklist_file);
# Associative array with all links found and their respectively deep
my %link_historic = ();


#########################################################################
#                                                                       #
# Recursive function to search a page through all links in a given page #
# Parameters:                                                           #
#              $current_page : the page to treat                        #
#              $deep : actual deep of the page                          #
#                                                                       #
# Return:                                                               #
# 	       True if the goal page is found                           #
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
		# For each links found save it in historic
		foreach my $keys (keys(%links)) {
			if (exists($link_historic{$keys}) && $link_historic{$keys}>($deep+1)) {
				print "Link $keys found less deeper at \($deep+1\)\n";
				$link_historic{$keys}=($deep+1);
			}elsif (exists($link_historic{$keys})) {
				print"$keys already visited\n";
				delete($links{$keys});
			}else{
			#	print "$keys record in historic\n";
				$link_historic{$keys}=($deep+1);
			}
		} 
		# For each links found in current page
		foreach my $keys (keys(%links)) {
			# Save the link in $tres array
			$tres[$deep+1] = article_name($keys);
			# If this link is no blacklisted
			if (!exists($blacklisted_link{$tres[$deep+1]})) {
				# Search goal page in this link
				if (search_page($wikipedia.$keys, ($deep+1))) {
					# If a result is found, it stop searching at that deep
					last;
				}
			}else{
				print "$tres[$deep+1] is blacklisted\n";
			}
		}
	}
	return $find;
	
}

####################################################
#                                                  #
# Function to extract the article name from a link #
# Parameter:                                       #
# 		$article_link : the link to treat  #
#                                                  #
# Return:                                          #
# 		the article name                   #
#                                                  #
####################################################
sub article_name {
	my ($article_link) = @_;
	($article_link) = $article_link =~ /\/wiki\/(.*$)/s;
	return $article_link;
}

#############################################
#                                           #
# Function to check to a file in the system #
# If it doesn't exist, it will be created   #
#                                           #
# Parameters:                               #
# 		$file: file name to check   #
#                                           #
#############################################
sub check_file {
	my ($file) = @_;
	# If the file doesn't exist
	if (! -e $file){
		print "$file file doesn't exist\n";
		# Creating the file
		if (open(NEWFILE, ">", $file)or die ("Can't create $file file\n")) {
			print "$file file created\n";
			close (NEWFILE);
		}
	}
}

##################################################################
#                                                                #
# Function to read a file and parse it into an associative array #
#                                                                #
# Parameters:                                                    #
# 		$file: file name to parse                        #
#                                                                #
# Return:                                                        #
# 		An associative array containing each lines of    #
#		the file as keys                                 #
#                                                                #
##################################################################
sub file_to_hash {
	my ($file) = @_;
	# Check to the file
	check_file($file);
	open (FILE, "<", $file) or die("Can't open location file\n");
	# Associative array where to save the file
	my %hash = ();
	# For each lines
	while (<FILE>) {
		chomp($_);
		# Save the line as a key of %hash
		$hash{$_} = 1;
	}
	close (FILE);
	return %hash;
}

#############
#           #
# Treatment #
#           #
#############

# Initialization of tres array with the start page
($tres[0]) = article_name($start_page); # =~ /\/wiki\/(.*$)/s;
# Save the start page in the historic with the deep 0
$link_historic{$tres[0]}=0;
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

#
# Blacklisting management
#
my $bl_result = "y";
while ($bl_result eq "y") {
	print "Blacklist a result (y/n)? : ";
	$bl_result = <STDIN>;
	chomp($bl_result);
	
	# If user want to blacklist a link
	if ($bl_result eq "y") {
		# Link choice to blacklist
		print ("Number of the result: ");
		my $result_number = <STDIN>;
		# If the number of the link is valid
		if (exists($paths[0][$result_number])) {
			open (BLACKLIST, ">>", $blacklist_file) or die("Can't open location file : $!\n");
			# Add the link to the blacklist
			if (print (BLACKLIST $paths[0][$result_number]."\n")) {
				print "$paths[0][$result_number] blacklisted\n\n";
			}
		}else{
			print "This value doesn't exists\n";
		}
	}
}
