## script for performing whole trial poisson analysis on synthetic dataset

#--------------------
#Jeff mohl
#last edit 6/7/18
#--------------------

## import analysis code
source("ICdualsound_analysis-new.R")

# One additional function, for fitting the data into the analysis, 
# modeled off poi.JA in above source
poi.JM <- function(fname, on.reward = TRUE, match.level = FALSE, AB.eqlevel = FALSE, outfile = "", start = 0, end = 600,thisData=""){
  infile1 <- paste(thisData, fname, ".txt", sep = "")
  trials <- read.table(infile1, col.names = c("TRIAL", "TASKID", "A_FREQ", "B_FREQ", "XA", "XB", "REWARD", "A_LEVEL", "B_LEVEL","SOFF"))
  
  infile2 <- paste(thisData, fname, "_spiketimes.txt", sep = "")
  spiketimes <- read.table(infile2, col.names = c("TRIAL2", "TIMES"))
  
  alt.pos <- c(24, -6)
  par(mfcol = c(1,2), mar = c(2,3,3,0) + .1)
  
  try({lbf <- round(esti.Poi(trials, spiketimes, c(1, 2), c(24, -6), on.reward, start, end, match.level, AB.eqlevel, FALSE), 4);
  cat(fname, c(2,-6, lbf), "\n", file = outfile, append = TRUE)})
}

#-------------------------------
## start of analysis script
#-------------------------------



for (this_lambda in c(1:length(lambdaPairs[,1]))){
  pairString <- paste(lambdaPairs[this_lambda,1],"v",lambdaPairs[this_lambda,2],sep="")
  pairPath <- paste(resultsPath,pairString,"/",sep="")
  dir.create(pairPath, showWarnings = FALSE)
  
  ## read triplet names for this firing rate pair
  fnames.complete <- scan(paste(dataPath,pairString,"Complete_List.txt",sep=""),"a")
  
  print(paste("Starting Run:",Sys.time()))
  #analysis is run on each control dataset separately, to make it easier to
  #analyze different expected results
  for (type in control.type) {
    fnames.JM = fnames.complete[grep(type,fnames.complete)] #this has a bug because "switch" "average" are repeated in conditions
    if (type == "switch"){
      fnames.JM= fnames.JM[!grep(type,fnames.JM) %in% grep("weak_switch",fnames.JM)]
    }
    if (type == "average"){
      fnames.JM= fnames.JM[!grep(type,fnames.JM) %in% grep("wt_average",fnames.JM)]
    }
    
    pdf(height = 8, width = 5, file = paste(pairPath,type,"_hists.pdf", sep =""))
    
    #run analysis for each file name in control type. 
    for (fname in fnames.JM) {
      try(poi.JM(
        fname,
        on.reward = TRUE,
        match.level = FALSE,
        AB.eqlevel = TRUE,
        outfile = paste(pairPath, type, "_bfs.txt", sep = ""),
        start=start.time,
        end=end.time,
        thisData = paste(dataPath, pairString, "/", type, "/", sep = "")
      ))
    }
    
    print(paste(type,Sys.time()))
    dev.off()
    
    #BFS processor
    #converts data into readable format, type used for post processing/figures
    
    bfs <- read.table(paste(pairPath,type,"_bfs.txt",sep=""))
    names(bfs) <- c("CellId","frq", "pos", "sep", "mix", "ave", "out", "dom", "pval1", "pval2", "pvalD")
    attach(bfs)
    
    all.bf <- data.frame(Mixture = mix, Average = ave, Outside = out, Single = dom)
    p.post <- exp(all.bf) / rowSums(exp(all.bf))
    summary(p.post)
    
    WinModel <- dimnames(p.post)[[2]][apply(p.post, 1, which.max)]
    post.probs <- as.data.frame(p.post)
    names(post.probs) <- c("PrMix", "PrAve", "PrOut", "PrSing")
    post.probs$WinModels <- WinModel
    post.probs$WinPr <- apply(post.probs[,1:4], 1, max)
    
    dd <- bfs[,c(1:4,9:10)]
    names(dd) <- c("CellId", "AltFreq","AltPos", "SepBF", "Pval1", "Pval2")
    full.dd <- cbind(dd, post.probs)
    write.csv(full.dd, file = paste(pairPath,type,"_poi.csv",sep=""), row.names = FALSE)
    detach(bfs)
  }
}


