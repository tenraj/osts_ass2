#!/usr/bin/env bash

#Input: Uncleaned CSV file.
#Output: Cleaned CSV file (Cyber_Security_Breaches_clean.tsv)
#This program takes a CSV file as an input and performs data cleaning such as dropping the unwanted columns, extracting months and years, removing extra texts etc.
#Author: Tenzin Namgyel (22559274)
#Date: May, 2023


#check if input file has been supplied to the program
if [[ $# -ne 1 ]]
then
	echo "Usage: $0 <.csv>" >/dev/stderr
	exit 1
else
    data=$1
	
	#check if the csv file exists and not zero lenth
    if [[ -f $data ]]
    then
		#do sanity checking
		
       
	    # remove the last two columns (Location of Breached Information and the Summary) and store in a temporary file named "cols_removed"
        tmp1="cols_removed.tsv"
        cut -f 6,7 --complement $data > $tmp1
		
        # remove characters after first comma or slash in Type of Breach column and store in temporary file
        tmp2="modified_c5.tsv"
        sed 's/\([^\t]*\t\)\{4\}\([^,\/]*\).*/\0\t\2/' $tmp1 | cut -f1,2,3,4,6 > $tmp2
		 
		# clean the Date_of_Breach column (remove the second date after hyphen)
		cut -f4 $tmp2 | sed 's/-.*//'| tr -d ' ' > dates.tsv
		
		#extract the months column and store in month.tsv
        echo "Month" > month.tsv
		tail -n +2 dates.tsv | cut -d'/' -f1 | sed 's/^0//' >> month.tsv
		
        #extract the year and convert 2-digit years for 4-digit years and store in year.tsv
        echo "Year" > year.tsv
        #tail +2 dates.tsv | cut -d'/' -f3 | sed 's/\b\([0-9][0-9]\)\b/20\1/g' >> year.tsv
		tail +2 dates.tsv | cut -d'/' -f3 | sed 's/^0*//'| while read year
		do
			# if there are only two digits, prefix either "20" or "19" depending on whether the 2 digit year is greater than 2023 or not
			if [ ${#year} -eq 2 ]
			then
				if [ $year -ge 23 ]
				then
					echo "19${year}">>year.tsv
				else
					echo "20${year}">>year.tsv
				fi
				#if the number of digit is 1, prefix with 200
			elif [ ${#year} -eq 1 ]
			then
				echo "200${year}">>year.tsv
			else 
				echo "${year}">>year.tsv
			fi
		done

        #create the final preprocessed file
        paste  $tmp2  month.tsv year.tsv > Cyber_Security_Breaches_clean.tsv
		
        # remove the temporary files
		rm dates.tsv
        rm year.tsv
		rm month.tsv
        rm $tmp1
        rm $tmp2
		
		# print the final output
		tail -n +1 Cyber_Security_Breaches_clean.tsv
    else
        echo "The CSV file you provided does not exist!" > /dev/stderr
        exit 1
    fi
fi
