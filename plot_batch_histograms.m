% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function plot_batch_histograms(results,sampleresults,outputsettings,linespecs)

n_conditions = numel(sampleresults);
n_colors = numel(linespecs);

fprintf('Plotting histograms');

% one bincount plot per condition
maxcount = 1e1;
for i=1:n_conditions
    h = figure('PaperPosition',[1 1 5 3.66]);
    set(h,'visible','off');
    replicates = sampleresults{i};
    numReplicates = numel(replicates);
    for j=1:numReplicates,
        counts = replicates{j}.BinCounts;
        bin_centers = results{i}.bincenters;
        for k=1:n_colors
            loglog(bin_centers,counts(:,k),linespecs{k}); hold on;
        end
        maxcount = max(maxcount,max(max(counts)));
    end
    for j=1:numReplicates,
        for k=1:n_colors
            loglog([results{i}.means(k) results{i}.means(k)],[1 maxcount],[linespecs{k} '--']); hold on;
        end
    end
    xlabel('CFP MEFL'); ylabel('Count');
    ylim([1e0 10.^(ceil(log10(maxcount)))]);
    if(outputsettings.FixedInputAxis), xlim(outputsettings.FixedInputAxis); end;
    %ylim([0 maxcount*1.1]);
    title([outputsettings.StemName ' ' results{i}.condition ' bin counts, by color']);
    outputfig(h,[outputsettings.StemName '-' results{i}.condition '-bincounts'],outputsettings.Directory);
    fprintf('.');
end;
fprintf('\n');
