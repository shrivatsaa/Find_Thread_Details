#!/bin/sh

usage="Run the script in the format ./GiveMeThreadDetails.sh <Date format in DD-Mon-YYYY>";

FolderPath=$PWD/$1;
red=$'\e[1;31m'
green=$'\e[1;32m'
blue=$'\e[1;34m'
white=$'\e[0m'
magenta=$'\e[1;35m'
combo=$'\e[3;4m'
cyan=$'\e[1;36m'
bold=$(tput bold)
normal=$(tput sgr0)

if [ $# -eq 0 ] ; then
	echo $usage;
	exit 1;
fi 


#Get the date for which you want to 
if [[ $2 != "" ]] ; then {
	if [[ $2 =~ ^[0-9]{2}-[A-Za-z]{3}-[2][0-9]{3}$ ]] ; then {
	Date=$2;	
	}
else {
      printf $blue'Please provide date in the format dd-Mon-YYYY : example 02-Feb-2023\n'$white
      exit;
    }
    fi
} 
else {
  printf $blue'No date given in commandline. Running script with today\n'$white
  Date=$(date +"%d-%b-%Y")
}
fi

#File name for access log
AccessLogFile=$(ls $FolderPath/access_log*);

#Threshold time for requests. Modify this to say 10000 if you want to capture only those requests that completed after 10 seconds as seen in access log.
WaitTime=4000;

#Find the position of the thread name in the access log
TDNamePosition=2; #Default value currently set. Modify the value here for the position of the thread name in access log entry

#Uncomment the below lines by removing # in every line including the last line containing fi. Uncomment if you cannot find by yourself the position of thread name in access log entry.
#TDNamePosition=$(cat $AccessLogFile | head -1 | awk -v pos=0 '{for(i=1;i<=NF;i++){if($i ~ /http-nio-.*exec/)pos = i}}{print pos}');
#if [[ TDNamePosition -lt 1 ]]; then {
#printf "$redAccess Log does not have thread identifier added.Exiting. $white"
#exit;
#}
#fi

# Internal for awk processing
AwkDate=$(echo $Date | awk -F "-" '{print $1"\\/"$2"\\/"$3":"}');

#Get a list of files from the folder path excluding access log, the script files and directories
FileList=(`ls -p $FolderPath | grep -v "/\|.sh\|access_log"`);

#Get the list of thread files excluding access log, the script files and directories
ThreadFiles=($(for filename in "${FileList[@]}"; do awk '{if ($0~/java.lang.Thread.State/){print FILENAME;exit}}' $FolderPath/$filename ; done));

#Times logged in the first line of each thread dump
ThreadTimes=$(for var in "${ThreadFiles[@]}"; do awk -v ORS="|" 'NR==1{print $2}' $var; done);

#Internal for awk processing
StartTime=$(echo $ThreadTimes | awk -F "|" '{print substr($2,1,7)}'); 

#Internal for awk processing
EndTime=$(echo $ThreadTimes | awk -F "|" '{print substr($(NF-1),1,7)}'); 

#Get the thread file extenstion to be used for thread dumps - might be used in future.
ThreadFileExt=$(for var in "${ThreadFiles[@]}"; do printf "%s\n" "$var";done | awk -F "." 'END{print $1".*"}'); 

#Gather the thread name, requesturl, Timetaken and username from access log within the timeperiod when the threaddumps were taken
awk "/$AwkDate$StartTime/","/$AwkDate$EndTime/"'{print}' $AccessLogFile | gawk -v Wait="$WaitTime" -v Pos="$TDNamePosition" '$12 > Wait{print $Pos,substr($5,14,20),$4,substr($8,length($8) - 40),$12}' | sort | while read line; \
#Print the details from access log. Then gather the thread state for the corresponding threads.                                          #Get the last thread stack frame from each matching thread from access log                                                                         # Do shell fu to print the thread stack frame in the same line
do printf "|%s" "$(echo $line | awk '{print $3"|"$4"|"$2"->"$5}')"; PrintVar=$(echo $line |awk '{print $1}'); printf "||%s|%s\n" "$PrintVar" "$(gawk "/\y$PrintVar\y/"'{getline;getline;print}' ${ThreadFiles[@]} | awk '{$1=$1};1' | sed -e 's/\(.*\)(.*)/\1/g' -e 's/at\ //g' | gawk -v FS="\n" -v OFS="|" -v RS="||" '{for(i=1;i<=NF;i++){printf "%s|", substr($i,1,40)}}')"; done | sed 's/||/|/g' | gawk -v TimeOfThread="$ThreadTimes" 'BEGIN {print "|Username","|Request","|RegisterTime->TimeTaken","|Thread_Name|",TimeOfThread}{print}' | column -t -s "|"  

exit;
