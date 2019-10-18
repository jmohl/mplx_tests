%% Mplx testing figure generation master
%
% -------------------
% Jeff Mohl
% last edit: 8/9/18
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
primary_rate_pairs=[30,20;50,20;100,20];
constant_sep_pairs_80=[5,1;15,3;25,5;50,10;100,20];
constant_sep_pairs_40 = [5,3;15,9;25,15;50,30;100,60];
%make plotting directories
try
    mkdir(sprintf('%s\\rasters',plotting_dir))
    mkdir(sprintf('%s\\avg_fr',plotting_dir))
    mkdir(sprintf('%s\\bar_plots',plotting_dir));
    mkdir(sprintf('%s\\power_plots',plotting_dir));
    mkdir(sprintf('%s\\hists',plotting_dir));
    mkdir(sprintf('%s\\phase_plots',plotting_dir));
end
%% Example datasets
%I orginally set this up to run on every control type, but that is unnecessary.
%Here I pick realistic datasets and run these examples only on those
%datasets. The primary purpose of these plots is to provide for direct
%comparison of the synthetic data with real data, and evaluate the expected
%performance of the model on realistic datasets

limited_n_repeats = [10,20,50];
example_rate_pair = [50,20];

for pair_ind = 1:size(example_rate_pair,1)
    pair_string = sprintf('%dv%d',example_rate_pair(pair_ind,1),example_rate_pair(pair_ind,2));
    for type_ind= 1:length(types)
        this_type = types{type_ind};
        for n_rep = limited_n_repeats
            %rasters and smoothed firing rate averages for example dataset
            run('raw_data.m') %done
            
            %bar plots for model performance on example dataset
            type_data = readtable(sprintf('%s\\%s\\%s_poi.csv', results_dir,pair_string,this_type));
            this_data = type_data(find(~cellfun(@isempty,strfind(type_data.CellId,sprintf('N%d-',n_rep)))),:);
            run('winning_models.m')
            %save both a jpg for review and an svg for publishing
            title(sprintf('Winning Model for type: %s \n %d trials per condition', types{type_ind},n_rep), 'interpreter', 'none')
            saveas(gcf,sprintf('%s\\bar_plots\\%s_%s_%dreps',plotting_dir,pair_string,types{type_ind},n_rep),'jpg')
            saveas(gcf,sprintf('%s\\bar_plots\\%s_%s_%dreps',plotting_dir,pair_string,types{type_ind},n_rep),'svg')
            close all;
        end
    end
end

%% Exploring model power
%The purpose of these plots is to evaluate the places where the model
%begins to break down, so that we know where it will fail and what that
%failure will look like
limited_types = {'Alike';'average';'outside';'switch'};
for pair_ind = 1:size(primary_rate_pairs,1)
    pair_string = sprintf('%dv%d',primary_rate_pairs(pair_ind,1),primary_rate_pairs(pair_ind,2));
    figure('visible','off')
    hold on;
    for type_ind= 1:length(limited_types)
        this_type = limited_types{type_ind};
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
    saveas(gcf,sprintf('%s\\power_plots\\%s',plotting_dir,pair_string),'jpg')
    saveas(gcf,sprintf('%s\\power_plots\\%s',plotting_dir,pair_string),'svg')
end
close all;

%% model power, combined across models (correct model winning % instead of
% posterior value)
for pair_ind = 1:size(primary_rate_pairs,1)
    pair_string = sprintf('%dv%d',primary_rate_pairs(pair_ind,1),primary_rate_pairs(pair_ind,2));
    figure();
    hold on;
    across_models_mat=[];
    for type_ind= 1:length(limited_types)
        this_type = limited_types{type_ind};
        results_matrix = [];
        for n_rep = n_repeats
            type_data = readtable(sprintf('%s\\%s\\%s_poi.csv', results_dir,pair_string,this_type));
            this_data = type_data(find(~cellfun(@isempty,strfind(type_data.CellId,sprintf('N%d-',n_rep)))),:);
            switch (this_type)
                case 'Alike'
                    cor_model = strcmp(this_data.WinModels, 'Single');
                case 'average'
                    cor_model = strcmp(this_data.WinModels, 'Average');
                case 'outside'
                    cor_model = strcmp(this_data.WinModels, 'Outside');
                case 'switch'
                    cor_model = strcmp(this_data.WinModels, 'Mixture');
            end
            results_matrix = vertcat(results_matrix,[n_rep, sum(cor_model)/length(cor_model)]);
        end
        %plot_tags(type) = plot(results_matrix(:,1),results_matrix(:,2),'-');
        plot(results_matrix(:,1),results_matrix(:,2),'.-')
        
        if ~isempty(across_models_mat) %pooling win rate across types
            across_models_mat = across_models_mat + .25*results_matrix;
        else
            across_models_mat = .25*results_matrix;
        end
    end
    plot(across_models_mat(:,1),across_models_mat(:,2),'.-k','LineWidth',2)
    title(pair_string);
    ylim([0,1])
    xlim([0,55])
    xlabel('N trials per condition')
    ylabel('% correctly classified')
    set(gcf,'Position',[100,60,1049,895])
    legend(limited_types,'mean across types');
    saveas(gcf,sprintf('%s\\power_plots\\%s_winct',plotting_dir,pair_string),'jpg')
    saveas(gcf,sprintf('%s\\power_plots\\%s_winct',plotting_dir,pair_string),'svg')
end
close all;

%% expanding power analysis to include a wider range of firing rates
% all firing rates have the same separation (80% firing rate decrease from peak rate)
limited_types = {'Alike';'average';'outside';'switch'};
for pair_ind = 1:size(constant_sep_pairs_80,1)
    pair_string = sprintf('%dv%d',constant_sep_pairs_80(pair_ind,1),constant_sep_pairs_80(pair_ind,2));
    figure('visible','on')
    hold on;
    for type_ind= 1:length(limited_types)
        this_type = limited_types{type_ind};
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
    %     saveas(gcf,sprintf('%s\\power_plots\\%s',plotting_dir,pair_string),'jpg')
    %     saveas(gcf,sprintf('%s\\power_plots\\%s',plotting_dir,pair_string),'svg')
end
% close all;

%% 2-d phase plot for accuracy
% Capturing a wider range of firing rate values in a plot showing model
% accuracy (percentage of conditions correctly labeled, across each model
% type) for various trial_number x peak firing rate pairs.
%build accuracy tables
limited_types = {'Alike';'average';'outside';'switch'};
all_results = cell(length(limited_types),1);

%have two datasets, one with 80% separation and one with 40% separation
for sep_amount = [40,80]
    
    if sep_amount == 40
        this_sep_pairs = constant_sep_pairs_40;
    else
        this_sep_pairs = constant_sep_pairs_80;
    end
    
    for pair_ind = 1:size(this_sep_pairs,1)
        pair_string = sprintf('%dv%d',this_sep_pairs(pair_ind,1),this_sep_pairs(pair_ind,2));
        for type_ind= 1:length(limited_types)
            this_type = limited_types{type_ind};
            results_vector = zeros(1,length(n_repeats));
            for rep_ind = 1:length(n_repeats)
                n_rep = n_repeats(rep_ind);
                type_data = readtable(sprintf('%s\\%s\\%s_poi.csv', results_dir,pair_string,this_type));
                this_data = type_data(find(~cellfun(@isempty,strfind(type_data.CellId,sprintf('N%d-',n_rep)))),:);
                switch (this_type)
                    case 'Alike'
                        win_cts = strcmp(this_data.WinModels,'Single');
                    case 'average'
                        win_cts = strcmp(this_data.WinModels,'Average');
                    case 'outside'
                        win_cts = strcmp(this_data.WinModels,'Outside');
                    case 'switch'
                        win_cts = strcmp(this_data.WinModels,'Mixture');
                end
                cor_perc = sum(win_cts)/length(win_cts);
                results_vector(rep_ind)=cor_perc;
            end
            all_results{type_ind}(pair_ind,:) = results_vector;
        end
    end
    %all_results is a cell array with 1 cell for each dataset type (eg
    %mixture), each cell contains an array where each row is a firing rate pair
    %and each column is a different number of trials.
    
    peak_rates = max(this_sep_pairs,[],2);
    
    % make figure as a shaded contour plot
    for cond_ind = 1:4
        figure
        contourf(n_repeats,peak_rates,all_results{cond_ind},[0 .25 .35 .45 .55 .65 .75 .85 .95 1.01 inf],'ShowText','on')
        colormap bone
        xlabel('N trials')
        ylabel('Peak Firing rate (Hz)')
        title(sprintf('model:%s, sep: %d',limited_types{cond_ind},sep_amount))
        saveas(gcf,sprintf('%s\\phase_plots\\%s_%d',plotting_dir,limited_types{cond_ind},sep_amount),'svg')
    end
    colorbar
    saveas(gcf,sprintf('%s\\phase_plots\\%s_%d',plotting_dir,limited_types{cond_ind},sep_amount),'svg')
    
    % same thing but now collapsing across all models
    all_results_collapse = (all_results{1} + all_results{2}+all_results{3}+all_results{4})/4;
    figure
    contourf(n_repeats,peak_rates,all_results{cond_ind},[0 .25 .35 .45 .55 .65 .75 .85 .95 1.01 inf],'ShowText','on')
    colormap bone
    xlabel('N trials')
    ylabel('Peak Firing rate (Hz)')
    title('Model Selection Accuracy')
    colorbar
    saveas(gcf,sprintf('%s\\phase_plots\\combined_%d',plotting_dir,sep_amount),'svg')
end


