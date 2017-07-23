% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function [results sampleresults] = per_color_constitutive_analysis(colorModel,batch_description,colors,AP)
% The 'results' here is not a standard ExperimentResults, but a similar scratch structure

warning('TASBE:UpdateNeeded','Need to update per_color_constitutive_analysis to use new samplestatistics');

% first do all the processing
rawresults = cell(size(colors));
for i=1:numel(colors),
    fprintf(['Processing for color ' colors{i} '...\n']);
    AP = setChannelLabels(AP,{'constitutive',channel_named(colorModel,colors{i})});
    rawresults{i} = process_constitutive_batch( colorModel, batch_description, AP);
end

n_conditions = size(batch_description,1);
bincenters = get_bin_centers(getBins(AP));

results = cell(n_conditions,1); sampleresults = results;
for i=1:n_conditions,
    replicatecounts = numel(rawresults{1}{i,2});
    samplebincounts = cell(replicatecounts,1);
    samplemeans = zeros(replicatecounts,numel(colors)); samplestds = samplemeans;
    results{i}.condition = batch_description{i,1};
    results{i}.bincenters = bincenters;
    for j=1:numel(colors),
        ER = rawresults{j}{i,1};
        SR = rawresults{j}{i,2};
        rawbincounts = getBinCounts(ER);
        results{i}.bincounts(:,j) = rawbincounts;
        results{i}.means(j) = geomean(bincenters',rawbincounts);
        results{i}.stds(j) =  geostd(bincenters',rawbincounts);
        % per-sample histograms
        for k=1:replicatecounts,
            samplebincounts{k}(:,j) = SR{k}.BinCounts;
            samplemeans(k,j) = geomean(bincenters',SR{k}.BinCounts);
            samplestds(k,j) = geostd(bincenters',SR{k}.BinCounts);
        end
        results{i}.stdofmeans(j) = geostd(samplemeans(:,j));
        results{i}.stdofstds(j) = mean(samplestds(:,j));
    end
    for k=1:replicatecounts,
        sampleresults{i}{k} = SampleResults([], [], [], samplebincounts{k}, samplemeans(k,:), samplestds(k,:), ...
            [], [], [], [], [], [], [], [], [], [], [], []);
    end
end

