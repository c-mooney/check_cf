=comment
This script looks for 3 conditions regarding the \cf.  
1. Determine if a \cf points to an existing \$LX_marker or \lc.   <do nothing>
2. Determine if \cf does NOT have a corresponding \$LX_marker or \lc. <note in log and update \cf to \cf_NF>
3. Determine if \cf points to the \$LX_marker in which it is found.  <note in log>

In order to check the \cf, I must also verify and add if necessary homograph numbers to the original file.  
That work is done first and is logged. 


#################  To execute:  #########################
Add input file name, output file name and logfile names to the script before running.  
Update $CF_marker for \cf and $LC_marker for \lc if necessary.

unix> perl check_cf.pl 

on Windows 

double click check_cf.pl from Windows Explorer.
-or-
open cmd window and enter with out quotes "perl check_cf.pl"

=cut

use feature ':5.10';
use Data::Dumper qw(Dumper);
use Time::Piece;
use Config::Tiny;

my $line_counter = 0;
my $row;
my @record;
my %fileArray;     #hash of entire file after hm corrections
my @controlArray;  #array of lexemes to insure output is in the same order as input file
my $hWord;
my $hm;
my $hWord_hm;
my $citForm;
my $lxRow;
my $cf_HWrd;
my @cf_Rec;
my @citForm_Array;   #array of citation forms which may match a cross ref
my $CRLF = "\n";
my @file_Array;     #array of the entire file before hm corrections
my %lx_Array;       #hash which links the lexmes to an array of homograph numbers
my @tmpRec;
my $TO_PRINT = "TRUE";    #Switch used to indicate no duplicates hm found in the file
my $DUPLICATE = "FALSE";
my @print_Array;    #array of entire file after hm corrections  
my @list_of_lexRel;  #array of lexical relations to check
my $CF_marker;
my $HM_marker;
my $LX_marker;
my $LC_marker;

my $date = localtime->strftime("%m/%d/%Y");

my $config = 'check_cf.ini';
#check for Windows running under linux
if ( $^O =~ /linux/)  {
	`dos2unix < $config  >/tmp/$config ` ;
	$config = '/tmp/'.$config;
}
$config = Config::Tiny->read('check_cf.ini') 
	or die "Could not open check_cf.ini $!";

my $infile = $config->{check_cf}->{infile};
my $outfile = $config->{check_cf}->{outfile};
my $log_file = $config->{check_cf}->{logfile};
$LC_marker = $config->{check_cf}->{citationForm_marker};
$HM_marker = $config->{check_cf}->{homograph_marker};
$LX_marker = $config->{check_cf}->{lexeme_marker};

my $list_to_check = $config->{check_cf}->{list_to_check};
if ( $list_to_check =~ ','){
	@list_of_lexRel = split(',', $list_to_check);
}
else {@list_of_lexRel = $list_to_check; }

open(my $fhlogfile, '>:encoding(UTF-8)', $log_file) 
	or die "Could not open file '$log_file' $!";

open(my $fhoutfile, '>:encoding(UTF-8)', $outfile) 
	or die "Could not open file '$outfile' $!";

open(my $fhinfile, '<:encoding(UTF-8)', $infile)
  or die "Could not open file '$infile' $!";


write_to_log("Input file $infile Output file $outfile   $date");

##########################  Add homographs if needed.  Verify no duplicates. ######################
# build a hash lexeme->[hm,hm,hm] or lexeme->[0] if it is not a homonym.
# Read the file into memory
 
while ( $row = <$fhinfile> ) {
      
	if ( $row =~ /^\\$LX_marker/ ) {
		$lxRow = $row;
		$hWord = substr $row, 4;

 		#remove any extra spaces at the beginning and end of the headword.
                $hWord =~ s/^\s+|\s+$//g; 

		if ( !exists $lx_Array{$hWord} ){
			@{$lx_Array{$hWord}{index}} = 0;
		}
		else {
	 		@tmpRec = @{$lx_Array{$hWord}{index}};
			push @tmpRec, 0;
			@{$lx_Array{$hWord}{index}} = @tmpRec;
		}

		push @file_Array, $lxRow;
	}
	elsif ( $row =~ /^\\$HM_marker/ ) { 
		my $hm_row = $row;
		#get the hm number
		$row =~ /\\$HM_marker\s+(\d+)/;
		$hm = $1;
	
		# add the hm number to the array associated with the key.
		
	 	@tmpRec = @{$lx_Array{$hWord}{index}};
		pop @tmpRec;
		push @tmpRec, $hm;
		@{$lx_Array{$hWord}{index}} = @tmpRec;
		push @file_Array, $hm_row;
	}
	elsif ( $row =~ /^\\_sh/  || $row =~ /^$/ ) {

		#do nothing

	}
	else {

		push @file_Array, $row; 

	}

}


#print Dumper(\%lx_Array);

#I've built my hash array of lexeme->[0|hm+].   Iterate through each of the hm lists and 
#fill in the zero's with the next largest number if the record is a homonym.
#
write_to_log("\n######### Checking homographs  ##########\n");

foreach my $key ( keys %lx_Array ){
my %seen;
my $hm_val;
my @dup_rec;

	$DUPLICATE = "FALSE";
	@tmpRec = @{$lx_Array{$key}{index}};
	if ( scalar @tmpRec > 1 ){
		#this is a homonym
		#check here to see if we have any duplicate \$HM_marker for this lexeme.
	 	@dup_rec = @tmpRec;
		@dup_rec = grep { $_  != 0 } @dup_rec;
		foreach $hm_val (@dup_rec){
			next unless $seen{$hm_val}++;
			$DUPLICATE = "TRUE";
		
		}
		if ($DUPLICATE eq "TRUE"){
			write_to_log(qq(CANNOT PROCEED: Duplicate homograph value for lexeme $key));
			$TO_PRINT = "FALSE";

	 	}	
		else {
			for (my $i=0; $i< scalar @tmpRec; $i++ ){
				if ( $tmpRec[$i] == 0 ){
					#get max number 
					my @sorted = sort { $a <=> $b } @tmpRec;
					my $largest = pop @sorted;
					$largest++;
					@tmpRec[$i]=$largest;
					write_to_log("Updating lexeme $key with hm $largest");
				}
			}
		}
	}
	@{$lx_Array{$key}{index}} = @tmpRec;
}

			

#print Dumper(\%lx_Array);




if ($TO_PRINT eq "TRUE"){

	foreach my $r (@file_Array){

		if ( $r =~ /^\\$LX_marker/ ){
	
			$hWord = substr $r, 4;
       		        $hWord =~ s/^\s+|\s+$//g; 
			push @print_Array, "\n";
			push @print_Array, $r;


			my $hm = shift @{$lx_Array{$hWord}{index}};
			if ( $hm > 0 ){
				my $tmpRow = "\\$HM_marker $hm\n";
				push @print_Array, $tmpRow; 
			}
		}
		elsif ($r =~ /^\\$HM_marker/) {}
		else { 
			push @print_Array, $r;	
			
		}
	}
}
else {
	write_to_log (qq(Duplicate \\$HM_marker values have been found. SFM file must be corrected.));
	print $fhoutfile (qq(No data has been written. See details in log file.));
	close $fhlogfile;
	close $fhinfile;
	close $fhoutfile;
	exit;
}


######  Verify cross refs.  If cf has no matching lexeme or citation form, update marker to $CF_marker_NF ########
#homographs checked and added if needed.  Now on to checking cross refs...

foreach $row (@print_Array) {
      
	if ( $row =~ /^\\$LX_marker/ ) {
		$lxRow = $row;
		$line_counter = 0;

		#add the headword to the controlArray.
		$hWord = substr $row, 4;

 		#remove any extra spaces at the beginning and end of the headword.
                $hWord =~ s/^\s+|\s+$//g; 
		
		push @controlArray, $hWord;
		$fileArray{$hWord}{record}[$line_counter++] = $lxRow;
	}
	elsif ( $row =~ /^\\$LC_marker/ ) { 
		#build citation form list. Must check this as well.
		
		$row =~ /\\$LC_marker\s+(.*)$/;
		$citForm = $1;

 		#remove any extra spaces at the beginning and end.
		$citForm =~ s/^\s+|\s+$//g; 

		#remove any extra digits representing sense numbers.

		push @citForm_Array, $citForm;
		$fileArray{$hWord}{record}[$line_counter++] = $row;
	}
	elsif ( $row =~ /^\\$HM_marker/ ) { 
		
		#get the hm number
		$row =~ /\\$HM_marker\s+(\d+)/;
		$hm = $1;

		# add the hm number to the headword to be used as a key
		$hWord_hm = $hWord.$hm;
		
		#because I changed the headword to use the hm number as well, I need to change 
		#the values in the control array and also the file array. 

		pop @controlArray; 
		push @controlArray, $hWord_hm;

	 	my @tmpRec = @{$fileArray{$hWord}{record}};
		delete $fileArray{$hWord};

		$line_counter = @tmpRec;
		$hWord = $hWord_hm;
		@{$fileArray{$hWord}{record}} = @tmpRec;
		$fileArray{$hWord}{record}[$line_counter++] = $row;
	}
	elsif ( $row =~ /^\\_sh/  || $row =~ /^$/ ) {

		#do nothing

	}
	else {

		$fileArray{$hWord}{record}[$line_counter++] = $row;
	}

}
 	
#print Dumper(\%fileArray);

foreach my $l (@list_of_lexRel){
	$CF_marker = $l;
	my $CF_marker_not_found = $CF_marker."_NF";
	write_to_log("\n########  Checking $CF_marker  #########\n");
	foreach my $i (@controlArray) {
		@record = @{$fileArray{$i}{record}};
		#process record... 
		foreach my $r (@record) {
			if ( $r =~ /^\\$LX_marker/ ) {
				$hWord = substr $r, 4;
                		$hWord =~ s/^\s+|\s+$//g; 
			}
			elsif ( $r =~ /^\\$CF_marker / ) {
				
				$r =~ /\\$CF_marker\s+(.*)$/;
				$cf_HWrd = $1;
                		$cf_HWrd =~ s/^\s+|\s+$//g; 
				#
				#remove digits indicating sense number. Pattern for homograph # and sense #'s 
				#is \cf word\d \d where the first \d is the homograph and the second digit is the sense 
				#note the sense number may be sense.subsense.  
				#
				#
				#use the word|hm combo to check the hash for matching key (lxhm).
				#removing sense numbering if any.
				$cf_HWrd =~ s/\s+\d.*//g;
				my $cf_check_lx = $cf_HWrd;
				#
				#use the word without homograph digits to check the citation form array.
				#
				$cf_HWrd =~ s/\d.*//g;
			
			
				if (length($cf_HWrd) > 0 ){
					if ($cf_check_lx eq $i ){   
						write_to_log("WARNING! \\$CF_marker $cf_HWrd is a cross ref to the record in which it's found: $i");
					}
					elsif (!exists $fileArray{$cf_check_lx} && !grep {$cf_HWrd eq $_} @citForm_Array  ) {
					
				  	#here is the interesting case.  If I haven't found a matching \$LX_marker or \lc 
					#then I need to update the original \cf line to \cf_NF (meaning cross ref Not Found).
				  	#
				 	$r =~ s/\\$CF_marker/\\$CF_marker_not_found/; 
					delete $fileArray{$i};
					@{$fileArray{$i}{record}} = @record;
					write_to_log("No match for  \\$CF_marker $cf_HWrd  - \\$LX_marker $hWord");
					}#elsif no match	
				}#length > 0 - not an empty string.
		    	} #elsif I found \cf
		}#foreach r
	} #foreach $i
}#foreach $list_to_check

#now print the file
foreach my $i (@controlArray) { 
	
@record = @{$fileArray{$i}{record}};
print $fhoutfile @record;
print $fhoutfile "\n";

}




sub write_to_log{

        my ($message) = @_;
	        print $fhlogfile $message;
		print $fhlogfile $CRLF;
}



close $fhlogfile;
close $fhinfile;
close $fhoutfile;

