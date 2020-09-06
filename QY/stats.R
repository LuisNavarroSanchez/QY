#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

path = args[1]
first = args[2]
thresholdepth = as.integer(args[3])
filteroption = args[4]
filterexpression = args[5]

#the working directory is moved to where the files that will be used are
setwd(path)
names = read.table('names', colClasses = 'character')
#once there, the file with all the sample names to be analysed is read (it has been previously created by files.sh)

for (i in 1:length(names[,1])){
  rmarkdown::render(paste(first,'/stats.Rmd',sep=''), clean = TRUE, knit_root_dir = path, #file stats.Rmd located in 'first' path
                    output_file =  paste("report_sample_", names[i,1], '_', Sys.Date(), ".html", sep=''), 
                    output_dir = './results/')
}
#one report is created for each of the samples
#for that purpose, stats.R calls stats.Rmd
#the reports are saved in the folder 'results' with the name specified in line 17, also in the working directory given by the user

rmarkdown::render(paste(first,'/overallstats.Rmd',sep=''), clean = TRUE, knit_root_dir = path, #file overallstats.Rmd located in 'first' path
                  output_file =  paste("Overall_report_", Sys.Date(), ".html", sep=''), 
                  output_dir = './results/')
#one overall report is created for all the samples
#for that purpose, stats.R calls overallstats.Rmd
#the report is saved in the folder 'results' with the name specified in line 25, also in the working directory given by the user
