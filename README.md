# check_cf
Perl script to check cross references (or other lexical relations) for accuracy (does it have a target \lx?) 
Usage:
Fill in and save the check_cf.ini file with the necessary information:
#infile=<name of SFM file to be checked.  Must be in current dir or include path>
#outfile=<name of SFM file after processing>
#logfile=<name of file containing log information> 
#list_to_check=<list of mark up tags used in the SFM to check. Format must be tag1,tag2,tag3, etc.  Ex: cf,an,sy>
#cit_form=<citation form mark up tag used in the SFM file.  If there are no citation forms, put NONE>
  
After editing and saving the check_cf.ini file, type check_cf.pl in a unix shell or windows command prompt (assuming you are in the same directory as the script), or in Windows, you may just double click the check_cf.pl icon from Windows Explorer. 

What this script does:

  Homographs--
  Verifies no duplicate homographs.  If there are duplicates, script will quit with error message to user indicating which lexeme has the   duplicate homograph.  Will add homographs as needed. 
  Log file will report which lexemes were updated with homographs.
  *note it is recommended that once inmported into Flex, the Flex utility "Reassign Homographs" should be run on the file to 
  insure proper homograph numbering.

  Lexical Relationships--
  For each of the lexical relationships in *list_to_check (e.g. cf,an,sy,re)* determine whether the target lexeme (or citation form)
  exists.  If it *does not exist*, write to the logfile indicating a reference was not found along with the lexeme where the lex. rel.
  was found.  eg.*No match for  \ra hegeta  - \lx heglaan*  "ra hegeta" is the unmatched lex. rel and it occurs in the record for 
  "lx heglaan".   
  
  The entry for a lex. rel. whose target is not found is changed in the output file so the lexicographer will be able to check it 
  later for accuracy.  The mark up tag is appended with _NF in the output file.  eg. \cf bat does not have a target lexeme, \lx bat, 
  and in the output file, this line will be written as \cf_NF bat.

  If a circular relationship is found in a record, meaning a lex. rel. exists and its target is the same as the lexeme of the record 
  in which it's found, a warning message will be written to the logfile.  eg. *WARNING! \cf c is a cross ref to the record in which 
  it's found: c* In this case a cross ref "c" has a target of "c".  
  
  

