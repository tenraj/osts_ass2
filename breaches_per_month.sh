#!/usr/bin/env bash

#Input: Cleaned CSV file (Cyber_Security_Breaches_clean.tsv)
#This program counts number of cyber instances for each month, calculate Median and Median Absolute Deviation
#Author: Tenzin Namgyel (22559274)
#Date: May 2023


#check if input file has been supplied to the program
if [[ $# -ne 1 ]]
then
	echo "Usage: $0 <.csv>" >/dev/stderr
	exit 1
else
    data=$1
    if [[ -f $data ]]
    then
		
		# Extract the month and corresponding counts of instances
       	tail -n +2 $data | cut -f6 | sort -n | uniq -c | awk '{print $2 "\t" $1}' >month_count.tsv
    
        ################   calculate median.  ####################
		#sort the counts
        sorted=$(cut -f2 month_count.tsv | sort -n)
        num_obs=$(echo "$sorted" | wc -l)
		
		#check if number of observation is odd
        if [[ $(($num_obs % 2)) -eq 1 ]]
        then
			#then the index of middle value (no. obs + 1)/2
			middle_ind=$((num_obs+1/2))
            median=$(echo "$sorted" | sed -n "${middle_ind}p")
        else
			#if number of observation is even, then median is the average of two middle values.
		    middle_ind=$((num_obs/2))
		    m1=$(echo "$sorted" | sed -n "${middle_ind}p")
		    m2=$(echo "$sorted" | sed -n "$((${middle_ind}+1))p")
		    #median=$(( (m1+m2)/2))
			#two decimal point is taken 
			median=$(echo "$m1 $m2" | awk '{printf "%.2f", (($1+$2)/2)}')
        fi
		echo "Median is: " $median
		
		####################  calculate MAD  #######################
		#calculate absolute deviation from median
		abs_dev=()
		for i in $sorted
		do
			#diff=$((median-i))
			diff=$(awk -v n1=$median -v n2=$i 'BEGIN{printf "%d\n", (n1-n2)}')
			#remove the "-" sign
			abs_dev+=("${diff#-}")
		done 
		
		#sort the array to find the median 
		sorted_abs_dev=($(printf '%s\n' "${abs_dev[@]}" | sort -n))
		
        if [[ $(($num_obs % 2)) -eq 1 ]]
        then
			middle_ind=$((num_obs+1/2))
            mad=${sorted_abs_dev[middle_ind-1]} 
        else
		    middle_ind=$((num_obs/2))
		    m1=${sorted_abs_dev[middle_ind-1]} 
		    m2=${sorted_abs_dev[middle_ind]} 
		    #mad=$(( (m1+m2)/2))
			mad=$(echo "$m1 $m2" | awk '{printf "%.2f", ($1+$2)/2}')
        fi
		echo "Median Absolute Deviasion is: " $mad
		
		######################  Convert the month format ##########################
		readarray -t counts < <(cut -f2 month_count.tsv)
		readarray -t months < <(cut -f1 month_count.tsv)
		month_names=(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

		# Loop through the month numbers and replace them with their corresponding names
		for i in "${!months[@]}"; do
		    num="${months[$i]}"
		    name="${month_names[$i]}"
		    months[$i]="${name}"
		done
		
		####################### print ++ or -- or nothing ################
		#calculate 1 MAD above the median
		#upper=$((median+mad))
		upper=$(awk -v n1=$median -v n2=$mad 'BEGIN{printf "%d\n", (n1+n2)}')
		#calculate 1 MAD below median
		#lower=$((median-mad))
		lower=$(awk -v n1=$median -v n2=$mad 'BEGIN{printf "%d\n", (n1-n2)}')
		
		
		#loop through to compare the count with upper and lower and print "++", "--" or nothing accordinlgy
		for ((i=0; i<$num_obs; i++))
		do
			if [[ ${counts[i]} -ge $upper ]]
			then
				echo "${months[i]} ${counts[i]} ++"
			elif [[ ${counts[i]} -le $lower  ]]
			then
				echo "${months[i]} ${counts[i]} --"
			else
				echo "${months[i]} ${counts[i]}"
			fi
		done
    else
        echo "The CSV file you provided does not exist!" > /dev/stderr
        exit 1
    fi
fi
