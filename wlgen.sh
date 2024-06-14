#!/bin/bash

# Wordlist Generator [ex-Yu edition]
# by Srdjan Rajcevic of Sectreme (C) 2024 [www.sectreme.com]

print_usage () {
	echo "Usage:"
	echo "$0 -lmd URL"
	echo "-l	Minimal length of words to fetch"
	echo "-m	Maximum length of words to fetch"
	echo "-d	Depth of the link crawling "
	echo "URL	URL to crawl"
}

# Colors
NC='\033[0m'		# Color reset
Red='\033[0;31m'        # Red
Green='\033[0;32m'      # Green
Yellow='\033[0;33m'     # Yellow

# Check for prerequisites

cewlexec="cewl"

echo "Checking for prerequisites..."

if [ -f "./CeWL/cewl.rb" ]; then
	prerequisites=("ruby" "git")
	cewlexec="./CeWL/cewl.rb"
elif [ command -v -- "cewl" > /dev/null 2>&1 ]; then
	prerequisites=("ruby" "git")
	cewlexec="cewl"
else
	prerequisites=("ruby" "git" "cewl")
fi

for i in ${prerequisites[@]};
do
        if ! command -v -- $i > /dev/null 2>&1;
        then
                echo -e "${Red}Missing $i.${NC} Installing..."
                if [ "$i" = "ruby" ]; then
                        sudo apt install ruby; gem install bundler; bundle install
                fi
                if [ "$i" = "git" ]; then
                        sudo apt install git
                fi
                if [ "$i" = "cewl" ]; then
                        git clone https://github.com/digininja/CeWL.git
                        chmod u+x ./CeWL/cewl.rb
                        cewlexec="./CeWL/cewl.rb"
                fi

        else 
                echo -e "$i ... ${Green}OK${NC}"
        fi
done

echo "Checking for ruby gems..."

pregems=("mime" "mime-types" "mini_exiftool" "nokogiri" "rubyzip" "spider")

for i in ${pregems[@]};
do
        if [ $(gem list -i "$i") = "false" ]; then
		echo -e "${Red}$i is missing.${NC} Installing..."
                gem install $i
        fi
done

ARGC=$#
if [ $ARGC -ne 7 ]; then
	print_usage
	exit 1
fi
URL=$7
OPTSTRING=":l:m:d:"

while getopts ${OPTSTRING} opt; do
	case ${opt} in
		l)
			length=${OPTARG}
			;;
		m)
			maxlength=${OPTARG}
			;;
		d)
			depth=${OPTARG}
			;;
		:)
			echo "Option -${OPTARG} requires an argument."
			print_usage
			exit 1
			;;
		?)
			echo "Unknown option: -${OPTARG}."
			print_usage
			exit 1
			;;
	esac
done

output="$(echo $URL | sed -e 's|^.*://||' | sed -e 's|/.*$||')"
outputfile="$output.wordlist"

clear
echo -e "${Yellow}Wordlist Generator [ex-YU Edition]${NC}"
echo -e "Copyright (C) 2024 Srdjan Rajcevic of Sectreme"
echo ""

# Crawling site and fetching words

echo -e "${Green}Crawling ${Yellow}$URL${Green} ...${NC}[Length: ${Red}$length${NC} Maxlength: ${Red}$maxlength${NC} Depth: ${Red}$depth${NC}]"
echo ""
$cewlexec --lowercase -u "wlcbe crawler 1.0" -w $output -m $length -d $depth $URL
echo -e "${Green}Done. ${NC}[$(wc -l < $output) words]"

outputcleaned="$output-cl"

# Removing words of length >$maxlength

sed -r '/^.{'$maxlength',}$/d' $output > $outputcleaned
rm $output

# Convert from utf-8 to ascii

step1="step1.txt"
step2="step2.txt"
step3="step3.txt"
finalstep="$output.final"

echo -e "${Green}Converting from utf-8 to ascii...${NC}"
echo -n "."
sed 's/\xc4\x91/d/g' $outputcleaned > $step1
echo -n "."
sed 's/\xc5\xbe/z/g' $step1 > $step2; rm $step1
echo -n "."
sed 's/[\xc4\x87,\xc4\x8d]/c/g' $step2 > $step3; rm $step2
echo "."
sed 's/\xc5\xa1/s/g' $step3 > $finalstep ; rm $step3; rm $outputcleaned
echo -e "${Green}Done. ${NC}[$(wc -l < $finalstep) words]"

# Sorting and removing duplicates

echo -e "${Green}Removing duplicates...${NC}"
sort $finalstep | uniq > $outputfile; rm $finalstep
echo -e "${Green}Done. ${NC}[$(wc -l < $outputfile) words]"
