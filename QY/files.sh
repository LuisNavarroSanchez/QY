#!/bin/sh

#the script will work in the directory given by the user
cd $1

#the reference file has FASTA format, therefore
#to save the name of the reference, only the first line is considered (head command) but without the > (sed command).
head -1 $2 | grep "^>" | sed 's/>//' > referencename
#the first line must start with > (FASTA format required for the reference file)
if ! [ -s referencename ];then
	echo "Error: Check that the reference file has FASTA format."
	rm referencename
	exit 1
fi

#to calculate the length of the reference, the characters are counted (awk command) but without considering the header (grep command)
referencelength=$(grep -v "^>" $2 | awk 'BEGIN{c=0}{c=c+length($0)}END{print c}')
#the length is checked
if [ $referencelength -eq 0 ]; then
	echo "Error: Check that the reference file has a reference sequence besides the header."
	rm referencename
	exit 1
else
	echo $referencelength > referencelength
fi

#the names of all the files to be analysed (ls command), which must have SAM format and end in .sam,
#are saved without the extension (sed command)
ls *.sam > name 2>/dev/null
sed 's/.sam//' name > names
rm name
if ! [ -s names ];then
	echo "Error: Check that the files of analysis end in .sam and are in this folder."
	rm referencelength referencename names
	exit 1
fi

echo "Processing the samples:"
#for each of the samples, i.e. line on the names file, the loop does
while IFS= read -r line
do
  echo $line
  if ! [ -s $line.sam ];then
	echo "Error: Check that your SAM .sam file is not empty."
	rm referencelength referencename names
	exit 1
  fi
#the .bam, .sorted and .sorted.bai files are created (information is sorted and indexed)
#those files are necessary for the subsequent analysis and can also be used for visualization
  samtools view -bS $line.sam > $line.bam 2>/dev/null
#.bam files are not created due to wrong input format
  if ! [ -s $line.bam ];then
	echo "Error: Check that your input file has SAM format."
	rm referencelength referencename names *.bam
	exit 1
  fi
  samtools sort -o $line.sorted $line.bam 2>/dev/null
#.sorted files are not created due to the error 'samtools sort: couldn't allocate memory for bam_mem'
  if ! [ -f $line.sorted ]; then
	echo "Error: Check the memory available in your system."
	rm referencelength referencename names *.bam
	exit
  fi
  samtools index $line.sorted 2>/dev/null
#two SAM files are created for the mapped and unmapped reads
#flag 4 indicates unmapped reads: -f 4 selects reads that fulfill the condition whereas -F 4 selects the opposite
  samtools view -F 4 $line.bam > $line.mapped 2>/dev/null
  samtools view -f 4 $line.bam > $line.unmapped 2>/dev/null
#the stats command in samtools provides some basic statistics of the mapping
#the information of interest is in the lines that start with ^SN (grep and cut commands are used to extract that information)
#inclusion of chimera number of reads necessary
  samtools stats $line.sorted 2>/dev/null | grep ^SN | cut -f 2- > $line.stats 
  samtools view -c -f 2048 $line.bam >> $line.stats 2>/dev/null
#the depth command in samtools provides information about the depth of sequencing; the -a option is used to include all the positions
#a header is included in the file
#only the information of the position and depth are selected (fields $2 and $3, but not the $1 which is the name of the reference)
  echo 'position depth' > $line.depth
  samtools depth -a $line.sorted 2>/dev/null | awk '{print $2, $3}' >> $line.depth
#to obtain the quality of the mapped reads, the 5th field of that file is selected (it corresponds to the MAPping quality)
  cut -f 5 $line.mapped > $line.qualityseq 2>/dev/null
#to obtain the quality per position, the mpileup command is used
#the option -a, to include all the positions, as well as the -A, to not discard anomalous reads, are considered
#the 6th is the field of interest; however, the quality is in ASCII code and needs to be transformed to decimal (od command)
#some other transformations are needed to finally obtain the average quality per position (commands sed, tr and awk)
#intermediate files are deleted
  samtools mpileup -a -A $line.sorted 2>/dev/null | awk '{print $6}' > $line.qualitypos 
  od -An -t u1 -w -v $line.qualitypos > n0
  sed 's/\<10\>/a\n/g' n0 > n1
  rm n0
  tr '\n$' ' ' < n1 > n2
  rm n1
  tr 'a' '\n' < n2 > n3
  rm n2
  awk '{sum = 0; for (i = 1; i <= NF; i++) sum += (10^(-($i-33)/10)); sum /= NF; print sum}' n3 > $line.qualitypos
  rm n3
  sed -i '$ d' $line.qualitypos
#the 12th field of the file (for the mapped reads), shows how many mismatches each read has when compared to the reference
  grep NM:i: $line.mapped 2>/dev/null | awk '{print $12}' | cut -c 6- > $line.mismaseq 
#the mpileup command is used again, but, now, taking into account the reference, to obtain the mismatches per position
#the 4th and 5th fields are selected, depth and read bases, respectively
#some transformations are needed to eliminate symbols not related to what matches or mismatches are and to transform indels
#as indels need to be counted only once (and their lenght must not affect the calculations)
#intermediate files are deleted
  samtools mpileup -a -A -f $2 $line.sorted 2>/dev/null | awk '{print $4, $5}' > mispos
  awk '{gsub("[0-9]+[a-zA-Z]+","n",$2)}1' mispos > mi
  rm mispos
  awk '{gsub("\^[acgtnACGTN]","",$2)}1' mi > mis
  rm mi
  awk '{gsub("[^acgtnACGTN]","",$2)}1' mis > $line.mismapos
  rm mis
#to determine the real variants, the mpileup bcftools command is used (samtools is deprecated), 
#which generates the genotype likelihoods per position
#the -d options allows to increase the depth per position (to 8000, which is the limit in samtools depth and mpileup)
#and -Ou indicates that the output file will be uncompressed bcf to save time
#the mpileup is connected to the call command which has the options -m for the calling method (=multiallelic caller),
#-v, so only positions with variants are included, -Ov (output file = uncompressed vcf)
#per default, the program assumes that is working with diploid organisms
#not the case for bacteria. Therefore, the ploidy file has to indicate that.
#variants are filtered depending on the user criteria
#finally, some information (=fields) is extracted with the awk, tr and sed commands (header is omitted: grep command)
  echo '* * * F 1' > ploidy
  bcftools mpileup -A -d 8000 -Ou -f $2 $line.sorted 2>/dev/null | bcftools call -mv -Ov --ploidy-file ploidy -o $line.calls 
  bcftools filter $3 "${4}" $line.calls -Ov -o $line.filteredcalls 2>/dev/null
  if [ $(grep -v '#' $line.filteredcalls | wc -l) -eq 0 ] 2>/dev/null; then
	echo "Warning: For this sample, there are no variants identified."
	echo "Check that the filter expression for bcftools was quoted and/or use a less stringent filter.\n"
  fi
  grep -v '##' $line.filteredcalls | awk '{print $2,$4,$5,$6,$8}' | awk '{gsub(".*DP=","DP=",$5)}1' | tr ';' '\t' | sed 's/DP=//;s/MQ=//' | awk '{print $1,$2,$3,$4,$5,$NF}' > $line.variants
  rm ploidy
done < names

#a new folder is created to save there all the results
#in case the user has a folder with the same name, it will be overwritten
if [ -d "$1/results" ]; then
	echo "Warning: The previously existing folder 'results' will be overwritten."
else
	mkdir "results"
fi

