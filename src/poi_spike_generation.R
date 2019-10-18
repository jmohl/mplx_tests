## functions for generating synthetic spike trains

#--------------------
#Jeff mohl
#last edit 2/15/17
#--------------------

#function descriptions
#----------------------
#gen_synth_binwise: allows for generation of spikes in different time bins of a
#single trial, can use different mean rates for each bin 
#makeSpikes: generates a 1 or 0 in each 1 ms time bin as a function of a random
#draw being smaller than the desired mean rate. This mimics the format of our
#actual data

## generate spikes in a binwise poisson fashion
gen_synth_binwise <- function(lambdaA,lambdaB=NULL, weight.factor = 1, mplx.rate=0 ,num.ctrials,start.time=0, end.time=1000, bw=(end.time-start.time)){
   #returns c counts after manufacturing Cs using poisson spike generator with input rate
   #pass in a vector of lambdas.
   #weight.factor is trial level switching, mplx.rate is within trials switching
   spikes <- matrix(0,num.ctrials,end.time-start.time)

   for (i in 1:num.ctrials){
      if (runif(1,0,1)<=weight.factor){
         lambda<-lambdaA #randomly picking distribution to draw from based on weight factor
         other.lambda <- lambdaB
      } 
      else {
         lambda <- lambdaB
         other.lambda <- lambdaA
      }
      if (mplx.rate !=0){
         for (bin in 1:length(lambda)){
            if (runif(1,0,1)<mplx.rate)lambda[bin] <- other.lambda[bin] #picking bin rate based on mplx rate
         }
      }
      spikes[i,]<-c(sapply(lambda,makeSpikes,start=1, end=bw))
      
   }
   #10/11/19
   #running into a problem here when I'm generating a lot of trials with 0
   #spikes. In our data we throw out 0 spike trials, but that isn't going to
   #work if the mean rate is ~1. solution is to just have every trial "start"
   #with 2 spikes if there are less than 2 spike. Doesn't affect analysis
   #because spike generation starts at -200 and analysis starts at 0 (time)
   if(sum(spikes)<2){spikes[1:2]=TRUE}
   #manipulating format to get spike times
   synth.times <-which(spikes==1,arr.ind=TRUE)
   synth.times <- synth.times[order(synth.times[,1]),]
   added.spikes <- synth.times+start.time
   
}

## poisson spike generator
#this code was adapted from http://www.hms.harvard.edu/bss/neuro/bornlab/nb204/statistics/poissonTutorial.txt
makeSpikes <- function(rate=50,start=0,end=1000){
  times <- seq(start,end)
  spikes <- vector("integer",length(times))
  vt <- runif(length(times),0,1)
  spikes <- vt <= (rate*.001)
  spikes
}


# #used to generate smoothly fluctuating firing rates (rather than bin defined). Didn't end up using
# gen_smooth_mplxd <- function(lambdaA,lambdaB=NULL ,num.ctrials,start.time=0, end.time=1000, bw=(end.time-start.time)){
#   #handling mplx differently by smoothly fluctuating from A to B
#   spikes <- matrix(0,num.ctrials,end.time-start.time)
#   
#   max_rate = lambdaA
#   min_rate = lambdaB
#   jit = sample(1:200,1)
#   t=seq(start.time:(end.time-1))
#   
#   for (i in 1:num.ctrials){
#     
#     # little ugly, but making the "rate" constantly fluctuate between max and min values
#     # BW sets the period of these fluctuations, in this case 200
#     lambda = ((sin((t+jit)/bw*2*pi)+1)/2*(max_rate-min_rate))+min_rate # hard coding in 6 periods
#     
#     spikes[i,]<- c(sapply(lambda,makeSpikes,start=1, end=1)) #1 ms bins for spike generation
#     
#   }
#   #manipulating format
#   synth.times <-which(spikes==1,arr.ind=TRUE)
#   synth.times <- synth.times[order(synth.times[,1]),]
#   added.spikes <- synth.times+start.time
# }
