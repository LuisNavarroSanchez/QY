# QY

The QY program has been developed to provide users a detailed analysis of mapping parameters.

It is useful for the analysis of next-generation sequencing experiments with bacterial DNA.

For each sample, number of (un)mapped reads, coverage, depth, quality (per read and per position), number of mismatches (per read and per position) and variants will be detailed.


---
### Input:

- Files containing mapping information (SAM format; header mandatory). 
It is necessary that all the files to be analyzed are located in the same directory and have names ending in .sam.

- In that directory, a file with the reference sequence (FASTA format) must be present. It is recommended to have it indexed.



### Output:

- For each sample, an individual html report as well as 4 different csv files.

- Plus a summary html report and a csv file with information regarding all the samples analyzed together.

- The information about depth, quality and number of mismatches per position can be visualized by launching a shiny app.

All the files will be saved in a folder named 'results'.

### Requirements:
- R, Rstudio (libraries knitr, ggplot2, egg, plotly and shiny).

- SAMtools 1.10 and BCFtools 1.10.2.



### Installation:
Download the folder containing all the scripts. Locate on it in the terminal and launch main.sh (sh main.sh -h, for usage details).
Remember to check that you have execution permission on delete.sh, files.sh, main.sh, move.sh and shiny.sh before launching the program.



### Support

Reach out to me at: <a href="http://www.linkedin.com/in/luis-navarro-sánchez-4963a138" target="_blank">`www.linkedin.com/in/luis-navarro-sánchez-4963a138`</a>

---
