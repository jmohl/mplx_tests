%% Plots for visualizing synthetic data

% -------------------
% Jeff Mohl
% last edit: 2/22/17
% -------------------

% Description: generate traiditional plots for synthetic datasets. These
% include a raster of all trials and a smoothed firing rate plot.

%depends on global variables set by the master script
%---------------------------------------------
%   mplx_dir:           directory for data and results
%   pair_string:        string giving firing rate pair
%   this_type:          control type used for this iteration
%   n_rep:              number of trials per condition for this iteration
%   example_rate_pair:  vector of given firing rate pair
%---------------------------------------------

aval = example_rate_pair(pair_ind,1);
bval = example_rate_pair(pair_ind,2);
raw_data_dir = sprintf('%s\\%s\\%s',data_dir,pair_string,this_type);
file_path = sprintf('%s\\%s-N%d-A%d-B%d-rep1_spiketimes.txt',raw_data_dir,this_type,n_rep,aval,bval); %arbitrarily using rep 1 for plotting rasters

%load data from spiketimes file
file_id = fopen(file_path,'r');
formatSpec = '%d %d';
sizeA = [2 Inf];
spiketimes = fscanf(file_id,formatSpec,sizeA);
fclose(file_id);

%first n_rep trials are A trials, then B trials, then AB
Aspikes = spiketimes(:,spiketimes(1,:) <= n_rep);
Bspikes = spiketimes(:,spiketimes(1,:) <=2*n_rep & spiketimes(1,:) > n_rep);
ABspikes = spiketimes(:, spiketimes(1,:) > 2*n_rep);

%% Raster of firing for all trials
figure('visible','off')
hold on;
for i = 1:length(Aspikes)
    plot([Aspikes(2,i) Aspikes(2,i)],[Aspikes(1,i)-0.4 Aspikes(1,i)+0.4], 'b');
end
for i = 1:length(Bspikes)
    plot([Bspikes(2,i) Bspikes(2,i)],[Bspikes(1,i)-0.4 Bspikes(1,i)+0.4], 'r');
end
% 6/12/18 reordering AB spikes by spike count for clarity on AB switching data
%not working yet
ABtrs = unique(ABspikes(1,:));
ABcounts = sortrows([ABtrs',histcounts(ABspikes(1,:))'],2); %[tr, count], sorted by count
ABspikes_sorted=ABspikes;
for i=1:length(ABtrs)
    ABspikes_sorted(1,ABspikes(1,:) == ABcounts(i,1)) = ABtrs(i); %replace with sorted tr number. rep added to make sure data isn't touched twice
end

for i = 1:length(ABspikes)
    plot([ABspikes_sorted(2,i) ABspikes_sorted(2,i)],[ABspikes_sorted(1,i)-0.4 ABspikes_sorted(1,i)+0.4], 'k');
end
ylim([0,n_rep*3+1]);
xlim([0,1000]); %only plotting 500 ms of time
xlabel('Time(ms)')
ylabel('Trial number')
title(sprintf('Spiking for condition: %s \n A=%d Hz B=%d Hz', this_type,aval,bval))
hold off;
set(gcf,'renderer','painters')
saveas(gcf,sprintf('%s\\rasters\\%s_%dreps_%s',plotting_dir,pair_string,n_rep,this_type),'svg')
saveas(gcf,sprintf('%s\\rasters\\%s_%dreps_%s',plotting_dir,pair_string,n_rep,this_type),'jpg')

%% spike count histograms
%add spike count histograms
figure()
hold on;
ABcounts = histcounts(ABspikes(1,ABspikes(2,:)<800)); %<800 to make total duration 1 second, for easy conversion to hz
Acounts = histcounts(Aspikes(1,Aspikes(2,:)<800));
Bcounts = histcounts(Bspikes(1,Bspikes(2,:)<800));
bins = 0:5:80;

histogram(Acounts,bins,'FaceColor',[.75,0,0],'EdgeColor',[.75,0,0],'FaceAlpha',.25)
histogram(Bcounts,bins,'FaceColor',[0,0,0.75],'EdgeColor',[0,0,.75],'FaceAlpha',.25)
histogram(ABcounts,bins,'FaceColor',[.25,.25,.25],'EdgeColor','k','FaceAlpha',.25)
legend('A counts','B counts','AB counts')

xlabel('Spike Count')
ylabel('Number of trials')
title(sprintf('spike count histograms: %s \n A=%d Hz B=%d Hz', this_type,aval,bval),'interpreter', 'none')
hold off;
set(gcf,'renderer','painters')
saveas(gcf,sprintf('%s\\hists\\%s_%dreps_%s',plotting_dir,pair_string,n_rep,this_type),'svg')
saveas(gcf,sprintf('%s\\hists\\%s_%dreps_%s',plotting_dir,pair_string,n_rep,this_type),'jpg')


%% plotting mean firing rate and error with sliding window
%200 ms sliding rectangular window for stats. smoothed with gaussian for
%plotting purposes only
figure('visible','on');
colors = {'b','r','k'};
transp_colors = [0,.25,.75,.1;.75,0,0,.1;.25,.25,.25,.1]; %colors for transparent confidence intervals
hold on;
for i = 1:3
    spikes = zeros(n_rep,1200);
    for trial = 1+n_rep*(i-1):n_rep*i
        this_trial = spiketimes(2,spiketimes(1,:)==trial);
        spikes(trial-(i-1)*n_rep,this_trial+200) = 1; %adding 200 ms to make everything positive time (started at -200 ms in spike generation)
    end
    
    this_avg = movmean(spikes,200,2)*1000;                                   %50 ms sliding window mean
    SEM = std(this_avg)/sqrt(n_rep);                                        % Standard Error of mean
    ts = tinv([0.025  0.975],n_rep-1);                                      % T-Score, n_rep - 1 deg of freedom
    CI = [];
    smoo_mean = conv(mean(this_avg,1),gausswin(50),'same')/sum(gausswin(50)); %divide by sum compensate for gausswin summing to more than 1.

    CI(1,:) = smoo_mean + ts(1)*SEM;                                 % .95 Confidence Intervals
    CI(2,:) = smoo_mean + ts(2)*SEM;                                 % .95 Confidence Intervals
    %smoothing for plot
    smoo_CI(1,:) = conv(CI(1,:),gausswin(50),'same')/sum(gausswin(50));
    smoo_CI(2,:) = conv(CI(2,:),gausswin(50),'same')/sum(gausswin(50));
    plot([0:1000;0:1000],smoo_CI(:,100:end-100),'color',transp_colors(i,:))                                %making transparent confidence intervals
    plot_handle(i)=plot(0:1000,smoo_mean(100:end-100),colors{i},'LineWidth',2);    %mean line
end

legend(plot_handle,'A trials',  'B trials', 'AB trials', 'Location', 'EastOutside')
xlim([0,1000])
ylim([0,80])    %this is an arbitrary choice for the examples I have chosen
xlabel('time(ms)')
ylabel('Firing Rate(Hz)')
title(sprintf('Avg FR for condition: %s \n n_reps=%d A=%d Hz B=%d Hz', this_type,n_rep,aval,bval),'interpreter', 'none')
set(gcf,'renderer','painters')
saveas(gcf,sprintf('%s\\avg_fr\\%s_%dreps_%s',plotting_dir,pair_string,n_rep,this_type),'jpg')
saveas(gcf,sprintf('%s\\avg_fr\\%s_%dreps_%s',plotting_dir,pair_string,n_rep,this_type),'svg')
close all;
