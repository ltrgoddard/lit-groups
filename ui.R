library(shiny)
library(networkD3)

fluidPage(title = "The Oxford Companion to Modern Poetry in English",

	br(),

	sidebarPanel(
		p(strong("Click and drag"), " to move the graph, ", strong("mouse-over"), " nodes to view the people that they represent, and ", strong("pinch or use the scroll wheel"), " to zoom."),
		sliderInput("birthdate", "Birthdate range", min = 1900, max = 2000, value = c(1945, 1955), step = 5),
        sliderInput("cutoff", "Weight cutoff", min = 0, max = 1, value = 0.75, step = 0.05),
		sliderInput("charge", "Strength of attractive force", min = -1000, max = 0, value = -200, step = 50),
        checkboxInput("community", "Community detection on/off", value = FALSE),
        p(a("Scoring equation", href="equation.jpg"), "/", a("Score table", href = "table.jpg")),
		p("Created by ", a("Louis Goddard", href = "http://louisg.xyz"), "/", a("Source code", href = "https://github.com/ltrgoddard/lit-groups")),
		p("Powered by ", a("R", href = "https://www.r-project.org/"), "/", a("D3.js", href = "https://d3js.org/"), "/", a("Shiny", href = "http://shiny.rstudio.com/"), "/", a("igraph", href = "http://igraph.org/"), "/", a("networkD3", href = "https://christophergandrud.github.io/networkD3/"))
	),

	mainPanel(
		forceNetworkOutput("display", height = 700)
	)
)
