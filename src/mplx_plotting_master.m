%% Mplx testing figure generation master
%
% -------------------
% Jeff Mohl
% last edit: 6/7/18
% -------------------
%
%Description: master script for generating the figures used in the mplx
%testing manuscript. Also sets various global variables that are used by
%many of the functions and scripts.

%% Shared Variables
local_dir = 'C:\Users\jtm47\Documents\projects\mplx_tests';
cd(local_dir)
addpath('src')
data_dir = sprintf('%s\\data',local_dir);
results_dir = sprintf('%s\\results',local_dir);
plotting_dir = sprintf('%s\\plots',results_dir);
% specify which control types and conditions should be plotted
types = {'Alike';'average';'outside';'switch';'weak_switch80';'weak_switch90';'wt_average'}; 
n_repeats=[5,10,20,30,50];
rate_pairs=[30,20;50,20;100,20];

%make plotting directories
try
    mkdir(sprintf('%s\\rasters',plotting_dir))
    mkdir(sprintf('%s\\avg_fr',plotting_dir))
    mkdir(sprintf('%s\\bar_plots',plotting_dir));
    mkdir(sprintf('%s\\line_plots',plotting_dir));
end
%% Example datasets
%I orginally set this up to run on every control type, but that is unnecessary.
%Here I pick realistic datasets and run these examples only on those
%datasets. The primary purpose of these plots is to provide for direct
%comparison of the synthetic data with real data, and evaluate the expected
%performance of the model on realistic datasets

limited_n_repeats = [5,10,50];
example_rate_pair = [50,20];

for pair_ind = 1:size(example_rate_pair,1)
    pair_string = sprintf('%dv%d',example_rate_pair(pair_ind,1),example_rate_pair(pair_ind,2));
    for type= 1:length(types)
        this_type = types{type};
        for n_rep = limited_n_repeats
            %rasters and smoothed firing rate averages for example dataset
            run('raw_data.m') %done
            
            %bar plots for model performance on example dataset
            type_data = readtable(sprintf('%s\\%s\\%s_poi.csv', results_dir,pair_string,this_type));
            this_data = type_data(find(~cellfun(@isempty,strfind(type_data.CellId,sprintf('N%d-',n_rep)))),:);
            run('winning_models.m') 
            %save both a jpg for review and an svg for publishing
            title(sprintf('Winning Model for type: %s \n %d trials per condition', types{type},n_rep), 'interpreter', 'none')
            saveas(gcf,sprintf('%s\\bar_plots\\%s_%s_%dreps',plotting_dir,pair_string,types{type},n_rep),'jpg')
            saveas(gcf,sprintf('%s\\bar_plots\\%s_%s_%dreps',plotting_dir,pair_string,types{type},n_rep),'svg')
            close all;
        end
    end
end

clearvars -except mplx_dir results_dir plotting_dir types n_repeats rate_pairs

%% Exploring model power
%The purpose of these plots is to evaluate the places where the model
%begins to break down, so that we know where it will fail and what that
%failure will look like
limited_types = {'Alike';'average';'outside';'switch'};
for pair_ind = 1:size(rate_pairs,1)
    pair_string = sprintf('%dv%d',rate_pairs(pair_ind,1),rate_pairs(pair_ind,2));
    figure('visible','off')
    hold on;
    for type= 1:length(limited_types)
        this_type = limited_types{type};
        results_matrix = [];
        for n_rep = n_repeats
            type_data = readtable(sprintf('%s\\%s\\%s_poi.csv', results_dir,pair_string,this_type));
            this_data = type_data(find(~cellfun(@isempty,strfind(type_data.CellId,sprintf('N%d-',n_rep)))),:);
            switch (this_type)
                case 'Alike'
                    win_pr = this_data.PrSing;
                case 'average'
                    win_pr = this_data.PrAve;
                case 'outside'
                    win_pr = this_data.PrOut;
                case 'switch'
                    win_pr = this_data.PrMix;
            end
            results_matrix = vertcat(results_matrix,[n_rep, mean(win_pr),var(win_pr)]);
        end
        %plot_tags(type) = plot(results_matrix(:,1),results_matrix(:,2),'-');
        errorbar(results_matrix(:,1),results_matrix(:,2),results_matrix(:,3))
    end
    title(pair_string);
    ylim([0,1])
    xlim([0,55])
    xlabel('N trials per condition')
    ylabel('Posterior for correct model')
    set(gcf,'Position',[100,60,1049,895])
    legend(limited_types);
    saveas(gcf,sprintf('%s\\line_plots\\%s',plotting_dir,pair_string),'jpg')
    saveas(gcf,sprintf('%s\\line_plots\\%s',plotting_dir,pair_string),'svg')
end
close all;


