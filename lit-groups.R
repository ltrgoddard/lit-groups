library(igraph)

# read and merge data
d <- read.csv("data/edges.csv")
g <- graph.data.frame(d, directed = F)
g <- simplify(g)
b <- read.csv("data/birthdates.csv")
V(g)$birthdate = as.character(b$birthdate[match(V(g)$name, b$ident)])
l <- read.csv("data/labels.csv")
V(g)$name = as.character(l$name[match(V(g)$name, l$ident)])

# define main parameters
step_limit <- 3
lower_limit <- 5
cutoff <- 0.75
group_dir <- "groups/"

file_names <- list.files(group_dir, full.names = T)
groups <- lapply(file_names, function(name) {
    group_members <- scan(name, what = "", sep = "\n")
})
names(groups) <- list.files(group_dir)
print(groups)

# general community detection algorithm
algo <- function(graph, cutoff, algorithm, step_limit, lower_limit) {
    wei <- delete.edges(graph, which(E(graph)$weight < cutoff))
    wei <- delete.vertices(wei, which(degree(wei) < 1))
    if (algorithm == "walktrap") {
        com <- walktrap.community(wei, weights = E(wei)$weight, steps = step_limit)
    } else if (algorithm == "edge.betweenness") {
        com <- edge.betweenness.community(wei, weights = E(wei)$weight)
    } else if (algorithm == "fastgreedy") { 
        com <- fastgreedy.community(wei, weights = E(wei)$weight)
    } else if (algorithm == "label.propagation") {
        com <- label.propagation.community(wei, weights = E(wei)$weight)
    } else if (algorithm == "spinglass") {
        com <- spinglass.community(wei, weights = E(wei)$weight, spins = 25)
    }
    communities <- delete.edges(wei, E(wei)[crossing(com, wei)])
    communities <- delete.vertices(communities, which(degree(communities) < 2))
    clus <- clusters(communities)
    communities <- delete.vertices(communities, which(clus$membership %in% which(clus$csize < lower_limit)))
    return(communities)
}

# scoring function
test <- function(group, graph) {
    clus <- lapply(decompose.graph(graph), function(guess) { get.vertex.attribute(guess, "name")})
    scores <- sapply(clus, function(guess) { 
        intersect <- length(intersect(group, guess))
        if(length(guess) <= intersect) {
            diff <- 0
        } else {
            diff <- length(guess) - intersect
        }
        return(c(intersect, diff))
    })
    score <- NULL
    score$hits <- max(scores[1,])
    score$size <- length(group)
    score$misses <- as.integer(scores[2,][which.max(scores[1,])])
    score$score <- round(score$hits / (score$size + score$misses), digits = 2)
    return(score)
}

# optimisation table function
optimise <- function(graph, algorithm, groups, steps) {
    results <- lapply(steps, function(step) {
        communities <- algo(graph, step, algorithm, step_limit, lower_limit)
        return(lapply(groups, function(group) { return(test(group, communities)$score) }))
    })
    results <- as.data.frame(do.call(cbind, results))
    colnames(results) <- steps
    return(results)
}

# generate subgraphs
chr <- induced.subgraph(graph = g, vids = which(as.integer(V(g)$birthdate) >= 1910 & as.integer(V(g)$birthdate) <= 1990))
clus <- clusters(chr)
main <- max(lengths(clus)) / 2
chr <- delete.vertices(chr, which(clus$membership %in% which(clus$csize < main)))
wei <- delete.edges(chr, which(E(chr)$weight < cutoff))
wei <- delete.vertices(wei, which(degree(wei) < 1))

cutoff <- 0.75
wtl <- algo(chr, cutoff, "walktrap", step_limit, lower_limit)

cutoff <- 0.9
wtt <- algo(chr, cutoff, "walktrap", step_limit, lower_limit)

#output figures for article
pdf(file = "figs/full.pdf")
plot(g, layout = layout.drl, vertex.label = NA, vertex.size = 0.01, edge.width = E(g)$weight / 2)

normal_plot <- function(graph, file_name) {
    pdf(file = paste("figs/", file_name, sep = ""))
    plot(graph, layout = layout.fruchterman.reingold, vertex.size = 0.01, label.cex = 0.5, edge.width = E(graph)$weight / 2)
}

normal_plot(wei, "chrono.pdf")
normal_plot(wtl, "loose.pdf")
normal_plot(wtt, "tight.pdf")
dev.off()

# output optimisation table
optimise(chr, "walktrap", groups, seq(0.6, 0.95, by = 0.05))
