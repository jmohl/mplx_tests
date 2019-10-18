## control experiment workflow master script
#
#
# Jeff mohl
# last edit 6/7/18
#
#
# Description: this script can be run to perform all steps of the mplx vetting 
# analysis. This includes synthetic data generation, running of poisson analysis
# code. Because some of these stages (particularly the poisson analysis) take a
# long time, it is recommended to run this script only once to generate new
# analysis and results and then perform plotting etc separately. If desired 

## Hardcoded section
#-------------------------
localPath = "C:/Users/jtm47/Documents/projects/mplx_tests/"
dataPath <- paste(localPath,"data/",sep="")
resultsPath <- paste(localPath,"results/",sep="")
srcPath <- paste(localPath,"src/",sep="")
setwd(srcPath)

## Generating synthetic data
#--------------------------
#synth_script is a script to generate the complete synthetic datasets. This
#scrip must be edited directly and should be run only once to generate the
#desired number/types of synthetic data.
#
#
# control types: specify what process is used for each type of data generation, defined in synth_trial_maker.R
# -Alike:AB trials use same lambda as A (winner take all type)
# -switch: Ab trials randomly use either lambda = A or lambda = B
# -average: AB trials use lambda = mean(lambdaA,lambdaB)
# -outside: AB trials are 1.2*lambdaA (lambda A is larger in these files)
# -weak_switch80: switching but A like trials = .8*lambdaA and B like trials are 1.2*lambdaB
# -weak_switch90: same but .9 and 1.1
# -wt_average: lambda AB = .75*lambdaA+.25*lambdaB

#----------------------------
#  Define parameters of control datasets to generate
#   file naming convention will reflect many of these parameters i.e.
#   switch-N50-A30-B20-rep75: 
#   switch control type, 50 trials per triplet, lambdaA=30 lambdaB=20, triplet#75 of 100

#VALUES USED IN DATA GENERATION FOR MANUSCRIPT ~12-15 HOURS

# lambdaPairs=rbind(c(20,30),c(20,50),c(20,100)) #setting pairs of firing rate differences for separation comparison
# control.type =c("Alike", "switch", "average", "outside", "weak_switch80","weak_switch90","wt_average")
# n_trials_vec=c(5,10,20,30,50) #number of trials to be simulated for each triplet
# repeats = 100   #number of files(triplets) to be generated for each condition
# bw=200          #Note:can not run correctly with only one bin, and total trial time must be evenly divisible by bin size
#                 #also: bw is only use in "mplxd" controls which have variable rates within trials, so not relevant for whole trial analysis
# start.time=-200 #in milliseconds, used for spike generation. analysis is usually run on 500 ms of data from 0-500, but some pre-0 time is recommended
# end.time=1000

#VALUES USED TO GENERATE ADDITIONAL POINTS FOR MORE COMPLETE POWER ANALYSIS ~ 18 hours

# lambdaPairs=rbind(c(5,1),c(15,3),c(25,5),c(50,10),c(5,3),c(15,9),c(25,15),c(50,30),c(100,60)) #setting pairs of firing rate differences for separation comparison
# control.type =c("Alike", "switch", "average", "outside")
# n_trials_vec=c(5,10,20,30,50) #number of trials to be simulated for each triplet
# repeats = 100   #number of files(triplets) to be generated for each condition
# bw=200          #Note:can not run correctly with only one bin, and total trial time must be evenly divisible by bin size
# #also: bw is only use in "mplxd" controls which have variable rates within trials, so not relevant for whole trial analysis
# start.time=-200 #in milliseconds, used for spike generation. analysis is usually run on 500 ms of data from 0-500, but some pre-0 time is recommended
# end.time=1000

#VALUES FOR ANALYSIS TRIAL RUN TO ENSURE CODE WORKING PROPERLY, USING ONLY A SMALL SAMPLE OF DATA, ~5 mins

lambdaPairs=rbind(c(50,20)) #setting pairs of firing rate differences for separation comparison
control.type =c("Alike", "switch", "average", "outside")
n_trials_vec=c(30) #number of trials to be simulated for each triplet
repeats = 10   #number of files(triplets) to be generated for each condition
bw=200          #Note:can not run correctly with only one bin, and total trial time must be evenly divisible by bin size
#also: bw is only use in "mplxd" controls which have variable rates within trials, so not relevant for whole trial analysis
start.time=-200 #in milliseconds, used for spike generation. analysis is usually run on 500 ms of data from 0-500, but some pre-0 time is recommended
end.time=1000


# run data generation script
source("synth_script.R")


## Performing analysis
#--------------------------
# experiments_synth is a script which will load the requisite analysis functions
# (none of which have been modified from suryas version), create the required
# results directories, and run the analysis on each data subset. The way it is
# set up right now it will run through every control type I have created, but
# this can be adjusted in the "hardcoded" section of the script

# Define which control datasets should be analyzed, and set parameters:
#--------------------------------
#optional, specify only certain datasets
#lambdaPairs=rbind(c(30,20),c(50,20),c(100,20))
#control.type = c("Alike","switch", "average","outside","weak_switch80","weak_switch90", "wt_average")
start.time=0 #in milliseconds, used for spike generation. analysis is usually run on 500 ms of data from 0-500, but some pre-0 time is recommended
end.time=600    
#--------------------------------

# run analysis
source("experiments_synth.R")

## Plotting
#-------------------------
# Plotting is done in matlab scripts