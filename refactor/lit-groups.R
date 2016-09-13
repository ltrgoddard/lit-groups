library(igraph)

# read and merge data
d <- read.csv("data/edges.csv")
g <- graph.data.frame(d, directed = F)
g <- simplify(g)
b <- read.csv("data/birthdates.csv")
V(g)$birthdate = as.character(b$birthdate[match(V(g)$name, b$ident)])
l <- read.csv("data/labels.csv")
V(g)$name = as.character(l$name[match(V(g)$name, l$ident)])

# set label font size
V(g)$label.cex <- 0.5

# define main parameters
step_limit <- 3
lower_limit <- 5
cutoff <- 0.75

# define group membership
movement <- c("Larkin, Philip", "Wain, John", "Jennings, Elizabeth", "Davie, Donald", "Enright, D. J.", "Gunn, Thom(son) William", "Holloway, John", "Conquest, (George) Robert (Ackworth)", "Amis, Kingsley")
new_york_school <- c("O'Hara, Frank", "Ashbery, John", "Koch, Kenneth", "Guest, Barbara", "Elmslie, Kenward", "Mathews, Harry", "Schuyler, James", "Berkson, Bill", "Berrigan, Ted", "Padgett, Ron", "Coolidge, Clark", "Harwood, Lee", "Ceravalo, Joseph", "Mayer, Bernadette")
cambridge_school <- c("Prynne, J. H. (Jeremy Halvard)", "James, John", "Mulford, Wendy", "Oliver, Douglas", "Riley, Peter", "Crozier, Andrew", "Forrest-Thomson, Veronica", "Milne, Drew", "Riley, Denise", "Riley, John", "Haslam, Michael", "Lopez, Tony", "Wilkinson, John")
black_mountain <- c("Olson, Charles", "Creeley, Robert", "Duncan, Robert", "Dorn, Edward", "Oppenheimer, Joel", "Wieners, John", "Williams, Jonathan", "Blackburn, Paul", "Eigner, Larry", "Levertov, Denise")
language <- c("Andrews, Bruce", "Bernstein, Charles", "Hejinian, Lyn", "Watten, Barrett", "Silliman, Ron", "Harryman, Carla")
groups <- list(movement, new_york_school, cambridge_school, black_mountain, language)
names(groups) <- c("Movement", "New York School", "Cambridge School", "Black Mountain", "Language Poets")

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
    clus <- clusters(graph)
    intersects <- numeric(length(clus$membership))
    diffs <- numeric(length(clus$membership))
    for (i in clus$membership){
        guess <- V(graph)[clus$membership == i]$name 
        intersects[i] <- length(intersect(group, guess))
        if (length(guess) <= intersects[i]) {
            diffs[i] <- 0 
        } else {
            diffs[i] <- length(guess) - intersects[i]
        }
    }
    score <- NULL
    score$hits <- max(intersects)
    score$size <- length(group)
    score$misses <- as.integer(diffs[which.max(intersects)])
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

png(file = "figs/full.png")
plot(g, layout = layout.drl, vertex.label = NA, vertex.size = 0.01, edge.width = E(g)$weight / 2)
dev.off()

chr <- induced.subgraph(graph = g, vids = which(as.integer(V(g)$birthdate) >= 1910 & as.integer(V(g)$birthdate) <= 1990))
clus <- clusters(chr)
main <- max(lengths(clus)) / 2
chr <- delete.vertices(chr, which(clus$membership %in% which(clus$csize < main)))
wei <- delete.edges(chr, which(E(chr)$weight < cutoff))
wei <- delete.vertices(wei, which(degree(wei) < 1))

png(file = "figs/chrono.png")
plot(wei, layout = layout.fruchterman.reingold, vertex.size = 0.01, edge.width = E(wei)$weight)
dev.off()

cutoff <- 0.75
wtl <- algo(chr, cutoff, "walktrap", step_limit, lower_limit)
png(file = "figs/loose.png")
plot(wtl, layout=layout.fruchterman.reingold, vertex.size=0.01, edge.width = E(wei)$weight)
dev.off()

cutoff <- 0.9
wtt <- algo(chr, cutoff, "walktrap", step_limit, lower_limit)
png(file = "figs/tight.png")
plot(wtt, layout=layout.fruchterman.reingold, vertex.size=0.01, edge.width = E(wei)$weight)
dev.off()

optimise(chr, "walktrap", groups, seq(0.6, 0.9, by = 0.05))
