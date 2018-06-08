## script to make synthetic datasets using poisson spike times
#
#--------------------
#Jeff mohl
#last edit 6/7/18
#--------------------
#
# Description: This script will generate synthetic data matching each of the
# controls specified in master_script.R, and save to the data directory

#functions for metadata and spike time generation
source("synth_trial_maker.R")

for (this_lambda in c(1:length(lambdaPairs[,1]))){
  lambdaAseed <- lambdaPairs[this_lambda,1]
  lambdaBseed <- lambdaPairs[this_lambda,2]
  pairPath <- paste(dataPath,lambdaAseed,"v",lambdaBseed,sep="")
  dir.create(pairPath, showWarnings = FALSE)
  rm("file.list")
  for (n_trials in n_trials_vec){
    for (this.control in control.type) {
      controlPath <- paste(pairPath,"/",this.control,sep="") 
      dir.create(file.path(pairPath,this.control), showWarnings = FALSE)
      for (rep in c(1:repeats)){
        #row 1:a, 2:b, 3:ab
        trial_nums <- matrix(seq(1:(n_trials*3)),3,n_trials,byrow=TRUE)

        #make trial matrix
        trial_data <- rbind(make_trial_data(trial.nums=trial_nums[1,], trial.type="A", pos=c(24,-2859)),
                            make_trial_data(trial.nums=trial_nums[2,], trial.type="B", pos=c(-6,-2859)),
                            make_trial_data(trial.nums=trial_nums[3,], trial.type="AB", pos=c(24,-6)))
        #make spike matrix
        rm(Aspikes,Bspikes,ABspikes,spike_data)
        lambdaA=rep(lambdaAseed,(end.time-start.time)/bw) # making lambdas constant, instead a vector that has different rates in different time bins
        lambdaB=rep(lambdaBseed,(end.time-start.time)/bw)
        Aspikes <- make_synth_data(trial.nums=trial_nums[1,], start.time = start.time, end.time = end.time, bw = bw,lambdaA=lambdaA,lambdaB=lambdaB,control.type="Alike")
        Bspikes <- make_synth_data(trial.nums=trial_nums[2,], start.time = start.time, end.time = end.time, bw = bw,lambdaA=lambdaA,lambdaB=lambdaB,control.type="Blike")
        ABspikes <- make_synth_data(trial.nums=trial_nums[3,], start.time = start.time, end.time = end.time, bw = bw,lambdaA=lambdaA,lambdaB=lambdaB,control.type=this.control)
        spike_data<-rbind(Aspikes,Bspikes,ABspikes)

        #write out files
        outfile<- paste(this.control,"-N",n_trials,"-A", lambdaAseed,"-B",lambdaBseed,"-rep",rep, sep = "")
        write(t(trial_data),file=paste(controlPath,"/",outfile,".txt",sep=""),ncolumns=10,sep="\t")

        spikeout <- paste(outfile,"_spiketimes.txt",sep="")
        write(t(spike_data),file=paste(controlPath,"/",spikeout,sep=""),ncolumns=2,sep="\t")

        if (exists('file.list')) file.list<-rbind(file.list,outfile)
        else file.list<-outfile

      }
    }
  }
  #create list of file names for each lambda pair
  write(file.list,file=paste(pairPath,"Complete_List.txt",sep=""))
}




