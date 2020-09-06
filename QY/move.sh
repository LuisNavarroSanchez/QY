#!/bin/sh

#the script works in the directory given by the user
cd $1

while IFS= read -r line
do
  mv $line.depthquality.csv results
  mv $line.variants.csv results
  mv $line.regionsdepth0.csv results
  mv $line.indelsize.csv results
done < names

mv Summary_allsamples.csv results
mv referencename results
mv referencelength results
mv names results
rm Freqdepthoverall.csv

