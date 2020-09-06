#!/bin/sh

usage () {	echo "How to use the QY program 
		Example: sh main.sh -p /home/luisns/Desktop/test -f chrom.fasta -D Y -d 5 -o -i -e '%QUAL>=25' 
		
		-h,	prints this help
		-p,	path to the files (absolute preferred although relative also accepted)
		-f,	FASTA file with the reference sequence (sequence data in one single line)
		-D,	deletion of the files created (except .bam, .sorted and .sorted.bai) [Y/n]
		-d,	up to this value (included), depth will also be considered 0 [integer]
		-o,	option for the bcftools filter (only -e and -i allowed)
		-e,	expression for the bcftools filter (with quotes)
			DO NOT FORGET TO QUOTE THE EXPRESSION
			In case no filter wants to be applied, -o -i -e '%QUAL>=0', for example, can be used.
		* -p, -f, -D, -d, -o, -e are mandatory parameters
	
		OUTPUT: 
			This program analyses mapping information saved in SAM format.
			For each sample of study, an individual report (html file) is generated with 
			statistics about (un)mapped reads, depth, coverage, quality (per position and per read),
			number of mismatches (per position and per read), and variants. 
			This information is saved in some .csv files too.
			In addition, for all the samples analised at the same time, an overall report is generated (html and .csv files) 
			to facilitate the comparison between samples for the different parameters.
			All the files are saved in a folder named 'results'.
			It is possible to launch a shiny app to check the values of depth, quality and number of mismatches per position
			for each sample.
			To do that, use the command line sh shiny.sh -p path_to_the_files -s sample_name

		CHECK:
			SAMtools 1.10 and BCFtools 1.10.2 are installed in your system as well as 
			R, Rstudio, pandoc and libraries knitr, ggplot2, egg, plotly and shiny.
			There is 1 SAM file per sample. The SAM files to be analysed end in .sam.
			Be aware that all the files ending in .sam present in the folder will be analysed.
			A reference genome (FASTA file) is also present in that folder.
			It is recommended to index the reference genome and keep the indexed files in that folder.
			Nevertheless, in case the reference genome is not indexed, SAMtools will create the indexes.
			At least there are 10Gb of free memory on your system."
		exit 1 ; }


#the options and arguments introduced by the user are checked to confirm that the instructions have been followed
#in case there is an error, an error message is shown as well as the usage norms
#the arguments for the different options are saved in variables that are used in the subsequent analysis of the files
if [ $1 = "-h" ] 2>/dev/null;then
	usage
else
	if [ $# -ne 12 ]; then
		echo "Error: The command to execute the program is not correct. Wrong number of fields.\n"
		usage
	else
		if ! [ $1 = "-p" -a $3 = "-f" -a $5 = "-D" -a $7 = "-d" -a $9 = "-o" -a ${11} = "-e" ]; then 
			echo "Error: Invalid options used.\n"
			usage
		else
			if ! [ -d "$2" ]; then
				echo "Error: The path to the files is incorrect."
				exit 1
			else 
				if ! [ -f "$2/$4" ]; then
					echo "Error: The reference file does not exist."
					exit 1
				else
					if ! [ $6 = "Y" -o $6 = "n" ]; then  
						echo "Error: The only possible options for -D are Y and n.\n"
						usage
					else
						if ! [ $8 -ge 0 ] 2>/dev/null; then
							echo "Error: Depth must be a positive, whole number.\n"
	        					usage
	        				else
							if ! [ ${10} = "-e" -o ${10} = "-i" ]; then   
			      					echo "Error: The only possible options for bcftools filter are -e and -i.\n"
								usage
							else
								while getopts :p:f:D:d:o:e: options; do
								  case ${options} in
								    p )
								      path=$OPTARG
								      ;;
								    f )
								      reference=$OPTARG
								      ;;
								    D )
								      delete=$OPTARG
								      ;;
								    d )
								      depth=$OPTARG
								      ;;
								    o )
								      filteroption=$OPTARG
								      ;;
								    e )
								      filterexpression=$OPTARG
								      ;;
								  esac
								done
							fi
						fi
					fi
				fi
			fi
		fi							
	fi
fi		
					

#if all the options and arguments are correct, the analysis starts
echo "\n"
echo "Welcome to the QY program."
echo "--------------------------\n"

#it is checked that SAMtools and BCFtools are installed and have the proper version
samtools --version > sam_vers 2>/dev/null
sam=$(head -1 sam_vers | sed 's/samtools //')
if ! [ $sam = "1.10" ];then
	echo "Error: Check that SAMtools 1.10 is installed."
	rm sam_vers
	exit 1
else
	bcftools --version > bcf_vers 2>/dev/null
	bcf=$(head -1 bcf_vers | sed 's/bcftools //')
	if ! [ $bcf = "1.10.2" ];then
		echo "Error: Check that BCFtools 1.10.2 is installed."
		rm sam_vers bcf_vers
		exit 1
	fi
fi
rm sam_vers bcf_vers

#it is checked too that R, Rstudio and pandoc are installed
if ! [ -x "$(command -v R)" ]; then
 	echo 'Error: R is not installed.'
 	exit 1
fi

if ! [ -x "$(command -v rstudio)" ]; then
 	echo 'Error: Rstudio is not installed.'
 	exit 1
fi

if ! [ -x "$(command -v pandoc)" ]; then
 	echo 'Error: pandoc is not installed.'
 	exit 1
fi

#in addition, a brief script is ran to check that the libraries needed are also installed
Rscript check.R 2>null
error=$(grep -c "Error" null)
if [ $error -gt 0 ];then
	echo "Error: Check that the libraries needed in R are installed (knitr, ggplot2, egg, plotly and shiny)."
	rm null
	exit 1
fi
rm null

#first, different files are created from the SAM and .sam files
./files.sh $path $reference $filteroption "$filterexpression" 
#the program stops and shows an explanatory error message in case the generation of the files is not possible
if [ $(echo $?) -eq 1 ]; then
	exit 1
fi

echo "Generating the reports...\n"
ROOT=$(realpath stats.R | sed 's/stats.R//')
Rscript stats.R $path $ROOT $depth $filteroption "$filterexpression" 1>/dev/null 2>null
#to check if there is any error during R script 
error=$(grep -c "Error" null)
if [ $error -gt 0 ];then
	echo "Error: Check the memory on your system. Files have been created but reports couldn't be generated."
	rm null
	exit 1
fi
rm null

if [ $delete = "Y" ] ; then
	./delete.sh $path 2>/dev/null
fi

#the reports and other files generated are moved to the folder 'results' (they are all grouped there)
./move.sh $path 2>/dev/null

echo "Thanks for using the QY program.\n"

