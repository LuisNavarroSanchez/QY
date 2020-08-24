# QY

The QY program has been developed to provide users a detailed analysis of important mapping parameters.

For each sample, number of (un)mapped reads, coverage, depth, quality (per read and per position), number of mismatches (per read and per position) and variants will be detailed.


---
### Input:
The QY program works with any type of file provided by the mapping tools as long as it has SAM format.

- Files containing mapping information (DNA). 
It is necessary that all the files to be analyzed end in .sam and are located in the same directory.

- In that directory, a file with the reference sequence (FASTA format) must be present. It is recommended to have it indexed.



### Output:
All the files will be saved in a folder named 'results'.

- For each sample, an individual html report as well as 4 different csv files.

- Plus a summary html report and a csv file with information regarding all the samples analyzed together.

- The information about depth, quality and number of mismatches per position can be visualized by launching a shiny app.



### Requirements:
- R, Rstudio (libraries knitr, ggplot2, egg, plotly and shiny).

- SAMtools 1.10 and BCFtools 1.10.2.



### Installation:
Download the folder containing all the scripts. Locate on it in the terminal and launch main.sh (sh main.sh -h, for usage details).



### Support

Reach out to me at: <a href="http://www.linkedin.com/in/luis-navarro-sánchez-4963a138" target="_blank">`www.linkedin.com/in/luis-navarro-sánchez-4963a138`</a>

---
