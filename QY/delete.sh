#!/bin/sh

#the script works in the directory given by the user
cd $1

while IFS= read -r line
do
  rm $line.mapped
  rm $line.unmapped
  rm $line.stats
  rm $line.depth
  rm $line.qualityseq
  rm $line.qualitypos
  rm $line.mismaseq
  rm $line.mismapos
  rm $line.calls
  rm $line.filteredcalls
  rm $line.variants
done < names
