%% bar graphs of winning models by hypothesis type

% -------------------
% Jeff Mohl
% last edit: 2/22/17
% -------------------

%Description: This script generates and saves bar plots that display the
%number of categorized triplets for each hypothesis considered by the
%poisson analysis, stacked for different posterior probabilities.

%note:requires that dataset has already been loaded in under name "this_data"
counts = cell(4,3);
labels = {'Single','Outside','Average','Mixture'};
i=1;

%generate a count matrix where each row is a control type and
%each column gives the different winning probabilities.
for label = 1:length(labels)
    this_label = this_data((find(~cellfun(@isempty,strfind(this_data.WinModels,labels(label))))),:);
    switch(labels{label})
        case 'Single'
            winpr = this_label.PrSing;
        case 'Average'
            winpr = this_label.PrAve;
        case 'Outside'
            winpr = this_label.PrOut;
        case 'Mixture'
            winpr = this_label.PrMix;
    end
    counts{i,1} = sum(winpr >=0.95);
    counts{i,2} = sum(winpr < 0.95 & winpr >= 0.5);
    counts{i,3} = sum(winpr < 0.5 & winpr >= 0.25);
    i=i+1;
end

%making bar plot
figure('visible','on');
b=bar(cell2mat(counts(:,:)),'Stacked');
set(gca, 'XTick', 1:4, 'XTickLabel', {'Sing','Out','Int','Mix'});
b(1).FaceColor =[.25,.25,.25]; %greyscale for now
b(2).FaceColor =[.5,.5,.5];
b(3).FaceColor =[.75,.75,.75];
ylim([0 100])
ylabel('# of conditions categorized')
legend('Post > 0.95', 'Post > 0.5', 'Post > 0.25','Location','northeastoutside')

% avg win probability for each condition
%     figure()
%     probs = mean([reps_20.PrSing,reps_20.PrAve,reps_20.PrOut,reps_20.PrMix]);
%     bar(probs)
%     set(gca, 'XTick', 1:4, 'XTickLabel', counts(:,1));
%     title(sprintf('Mean Posterior Probability for dataset: %s \n 20 trials per condition', types{type}),'interpreter','none')
%     ylabel('Posterior Probability')
%     ylim([0,1])
%     saveas(gcf,sprintf('%s\\Bar_plots\\100v10hz\\%s-selected_prob',plotting_dir,types{type}),'png')
%

