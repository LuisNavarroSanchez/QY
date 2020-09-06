#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

path = args[1]
sample_name = args[2]

#with this, the warnings will not appear in the terminal
options(warn = -1)

#loading of the libraries
library(shiny)
library(ggplot2)

setwd(path)
#to where the files to be used are
#the name of the file of interest is created
file_name = paste(sample_name,'.depthquality.csv',sep = '')

#the data is read
information = read.table(file_name, header = TRUE, sep = ',')
#and also the reference length as it is used for the calculations
referencelength = as.numeric(read.table('referencelength'))

#the title of the app is
mtitle = paste('Sample:',sample_name, sep = ' ')
information[is.na(information)] = -0.2
#there are some fields for the relative percentage that are empty
#the NA on them will change to -0.2. It is just an arbitrary label, 
#to indicate that those positions don't have information there
#it is necessary to give them a value because, if not, those positions will never appear due to the slide range
#which is numerical

#the UI for application is defined
ui <- fluidPage(
        
#application title
titlePanel(mtitle),

#the sidebar has some slider inputs (for depth, quality and relative percentage) and a graph for the coverage
#the graph is reactive and shows the coverage depending on the characteristics selected for the 3 variables
    sidebarLayout(
        sidebarPanel(
            helpText("Detailed description, per position, of depth, quality (ASCII) and relative percentage of mismatches."),
#the quality and the relative percentage can range between 2 values selected by the user
            sliderInput(inputId = "depth", label = "Depth", value = 10, min = 0, 
                        max = 100),
            sliderInput(inputId = "quality", label = "Quality", min = 0, 
                        max = 120, value = c(40,60)),
            sliderInput(inputId = "relative_percentage", label = "Relative percentage", min = -0.2, 
                        max = 1, value = c(0.4, 0.6)),
            helpText("Arbitrary value -0.2 given to positions with depth = 0 for this calculation. It equals to NA.\n
                     The command used for the determination of the mismatches, recalculated the depth\n
                     using quality criteria, being, therefore, more restrictive. As a consequence,\n
                     more positions were considered with depth = 0 for the mismatches calculation.\n
                     That is the explanation for the higher number of positions with\n
                     relative percentage = -0.2 compared to those with depth = 0."),
            plotOutput("positions")
        ),
#in the main panel, a table for the positions that fulfill the criteria will be displayed
        mainPanel(
            dataTableOutput("table")
        )
    )
)
#the server logic is defined
server <- function(input, output, session) {
#this is necessary to allow the outputs (plot and table) to react to changes in the 3 selection criteria
    data = reactive({
        information[which(information$quality>=min(input$quality) & information$quality<=max(input$quality)  
                    & information$depth>=input$depth &
                    information$relative_percentage>=min(input$relative_percentage) 
                    & information$relative_percentage<=max(input$relative_percentage)),]
    })
#the plot on the slidebar reacts to the criteria
    output$positions = renderPlot({
        slices = c(nrow(data()), referencelength-nrow(data()))
        lbels = c("covered", "not\ncovered")
        pct = round(slices/sum(slices)*100, digits = 3)
        lbels = paste(lbels, pct, sep="\n") #adds percents to labels
        lbels = paste(lbels,"%",sep="") #adds % to labels
        pie(slices, labels = lbels,
            main="Percentage of the genome") 
    })
#as well as the table on the main panel
    output$table = renderDataTable({
        table = data ()
    })
#the app stops once the webpage is closed
    session$onSessionEnded(function() {
        stopApp()
    })
}
#the application runs
shinyApp(ui = ui, server = server)
    