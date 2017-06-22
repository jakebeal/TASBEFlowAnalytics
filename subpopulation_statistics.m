% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function [counts means stds excluded] = subpopulation_statistics(BSeq,data,selector,mode)

bedges = get_bin_edges(BSeq);

n = numel(bedges)-1;
ncol = size(data,2);

nbins = get_n_bins(BSeq);


counts = zeros(nbins,1); means = counts; stds = counts; % create zero sets

switch(mode)
    case 'geometric'
        for i=1:n
            which = find(data(:,selector)>bedges(i) & data(:,selector)<=bedges(i+1));
            counts(i) = numel(which);

            for j=1:ncol
%                 % to exclude outliers, drop top and bottom 0.1% of data
%                 sorted = sort(data(which,j));
%                 dropsize = ceil(numel(sorted)*0.001);
%                 if(numel(sorted)-2*dropsize > 0)
%                     trimmed = sorted(dropsize:(numel(sorted)-dropsize));
%                 else
%                     trimmed = sorted;
%                 end
                trimmed = data(which,j);

                means(i,j) = geomean(trimmed);
                stds(i,j) = geostd(trimmed);
            end
        end
      
    case 'arithmetic'
        for i=1:n
            which = find(data(:,selector)>bedges(i) & data(:,selector)<=bedges(i+1));
            counts(i) = numel(which);
            
            for j=1:ncol
%                 % to exclude outliers, drop top and bottom 0.1% of data
%                 sorted = sort(data(which,j));
%                 dropsize = ceil(numel(sorted)*0.001);
%                 if(numel(sorted)-2*dropsize > 0)
%                     trimmed = sorted(dropsize:(numel(sorted)-dropsize));
%                 else
%                     trimmed = sorted;
%                 end
                trimmed = data(which,j);

                means(i,j) = mean(trimmed);
                stds(i,j) = std(trimmed);
            end
        end
        
    otherwise
        error('Unknown statistical mode %s',mode);
end

excluded = size(data,1) - sum(counts);

end
