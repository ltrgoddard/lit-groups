library(shiny)
library(networkD3)

fluidPage(title = "Mapping literary groups with graph theory",

	br(),

	sidebarPanel(
		h3("Mapping literary groups with graph theory"),
        p("This interactive graph shows communities identified by the ", a(em("Walktrap"), href = "http://arxiv.org/abs/physics/0512106"), " algorithm in the online version of ", a(em("The Oxford Companion to Modern Poetry"), href = "http://www.oxfordreference.com/view/10.1093/acref/9780199640256.001.0001/acref-9780199640256"), ". Connections are based on links between entries."),
        p(strong("Click and drag"), " to move the graph, ", strong("mouse-over"), " nodes to view the people that they represent, and ", strong("pinch or use the scroll wheel"), " to zoom."),
		sliderInput("birthdate", "Birthdate range", min = 1900, max = 2000, value = c(1940, 1965), step = 5),
        sliderInput("cutoff", "Weight cutoff (based on age)", min = 0, max = 1, value = 0.75, step = 0.05),
		sliderInput("charge", "Strength of attractive force", min = -1000, max = 0, value = -100, step = 50),
        checkboxInput("community", "Community detection on/off", value = TRUE),
        p(a("Scoring equation", href="equation.jpg"), "/", a("Score table", href = "table.jpg")),
		p("Created by ", a("Louis Goddard", href = "http://louisg.xyz"), "/", a("Source code", href = "https://github.com/ltrgoddard/lit-groups")),
		p("Powered by ", a("R", href = "https://www.r-project.org/"), "/", a("D3.js", href = "https://d3js.org/"), "/", a("Shiny", href = "http://shiny.rstudio.com/"), "/", a("igraph", href = "http://igraph.org/"), "/", a("networkD3", href = "https://christophergandrud.github.io/networkD3/"))
	),

	mainPanel(
		forceNetworkOutput("display", height = 700)
	)
)
