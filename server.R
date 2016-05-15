library(shiny)
library(igraph)
library(networkD3)
source("igraph_to_networkD3_mod.R")

d <- read.csv("edges.csv")
g <- graph.data.frame(d, directed = FALSE)
g <- simplify(g)
b <- read.csv("birthdates.csv")
V(g)$birthdate = as.character(b$birthdate[match(V(g)$name, b$ident)])
l <- read.csv("labels.csv")
V(g)$name = as.character(l$name[match(V(g)$name, l$ident)])

function(input, output) {

   	graph <- reactive({
        
        g <- delete.vertices(g, which(V(g)$birthdate < input$birthdate[1]))
        g <- delete.vertices(g, which(V(g)$birthdate > input$birthdate[2]))
        g <- delete.edges(g, which(E(g)$weight < input$cutoff))
		g <- delete.vertices(g, which(degree(g) < 2))
        
        if(input$community == TRUE) {
		
            com <- walktrap.community(g, weights = E(g)$weight)
            communities <- delete.edges(g, E(g)[crossing(com, g)])
            communities <- delete.vertices(communities, which(degree(communities) < 2))
            clus <- clusters(communities)
            communities <- delete.vertices(communities, which(clus$membership %in% which(clus$csize < 5)))
            igraph_to_networkD3(communities, group = membership(clusters(communities)))
        } else { igraph_to_networkD3(g, group = V(g)) }
	})

    charge <- reactive({input$charge})

    output$display <- renderForceNetwork({
        validate(need(try(graph()$nodes != 0), "No connections found! Try increasing the birthdate range or decreasing the minimum connection weight."))
        forceNetwork(Links = graph()$links, Nodes = graph()$nodes, Source = "source", Target = "target", NodeID = "name", Group = "group", zoom = TRUE, bounded = TRUE, fontSize = 30, opacity = 1, charge = charge(), linkWidth = JS("function(d) { return Math.sqrt(d.value)/3; }"), colourScale = JS("d3.scale.category10()"))
    })
}
