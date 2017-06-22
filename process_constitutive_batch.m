% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function results = process_constitutive_batch( colorModel, batch_description, analysisParams, OSbin)
% batch_description is a cell-array of: {condition_name, filenames}
% results is a cell-array of {ExperimentResults, {SampleResults}}

batch_size = size(batch_description,1);

% Begin by scanning to make sure all expected files are present
fprintf('Confirming files are present...\n');
for i = 1:batch_size
    fileset = batch_description{i,2};
    for j=1:numel(fileset),
        if ~exist(fileset{j},'file'),
            error('Could not find file: %s',fileset{j});
        end
    end
end

results = cell(batch_size,2);
for i = 1:batch_size
    condition_name = batch_description{i,1};
    fileset = batch_description{i,2};
    
    experiment = Experiment(condition_name,'', {0,fileset});
    fprintf(['Analyzing ' condition_name '...\n']);
    sampleresults = process_data(colorModel,experiment,analysisParams);
    results{i,1} = summarize_data(colorModel,experiment,analysisParams,sampleresults);
    results{i,2} = sampleresults{1};
    
    if nargin>3, % if supplied an output setting, dump bincounts files
        OStmp = OSbin; OStmp.StemName = [OStmp.StemName '-' condition_name];
        plot_bin_statistics(sampleresults,OStmp);
    end
end
