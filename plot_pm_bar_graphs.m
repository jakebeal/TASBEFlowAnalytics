% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function plot_pm_bar_graphs(dataset,OS,plus_high,count_threshold,low_threshold)
% Given a dataset make of plus/minus results, plot two bar graphs giving the mean behaviors:
% 1. single bar with ratios
% 2. two bars, one with plus the other with minus
% Dataset is cells of: {condition_name, pm_result, index into pm_result}

if (nargin < 3 || isempty(plus_high)), plus_high = 1; end;
if (nargin < 4 || isempty(count_threshold)), count_threshold = 100; end;
if (nargin < 5 || isempty(low_threshold)), low_threshold = 1; end;

if plus_high
    high = 1; low = 2; % for activation relations
else
    high = 2; low = 1; % for repression relations
end
if isempty(OS.FigureSize), figsize = [1 1 6 4]; else figsize = OS.FigureSize; end;

pm_high_use_fn = @(ins,counts,valid)(ins(:,:,1)>=low_threshold & ins(:,:,2)>=low_threshold & counts(:,:,1)>=count_threshold & counts(:,:,2)>=count_threshold & valid(:,:,1) & valid(:,:,2));

ratio = zeros(size(dataset,1),1);
stdratio = zeros(size(dataset,1),1,2);
plusminus = zeros(size(dataset,1),2);
stdplusminus = zeros(size(dataset,1),2,2);
counts = zeros(size(dataset,1),2);

n_conditions = size(dataset,1);

for i=1:n_conditions,
    idx = dataset{i,3};
    data = dataset{i,2};
    
    which = pm_high_use_fn(data.InMeans(:,idx,:),data.BinCounts(:,idx,:),data.Valid(:,idx,:));
    ratio(i) = mean(data.OutMeans(which,idx,high)./data.OutMeans(which,idx,low));
    ratiostd = std_geo_of_ratio(data.OutMeans(which,idx,high),data.OutMeans(which,idx,low),...
                data.OutStdOfMeans(which,idx,high),data.OutStdOfMeans(which,idx,low));
    geoerr = mean(ratiostd);
    stdratio(i,1,:) = geo_error_bars(ratio(i),geoerr^2);
    
    plusminus(i,1) = geomean(data.OutMeans(which,idx,high));
    counts(i,1) = sum(data.BinCounts(which,idx,high));
    plusminus(i,2) = geomean(data.OutMeans(which,idx,low));
    counts(i,2) = sum(data.BinCounts(which,idx,low));
    stdplusminus(i,1,:) = geo_error_bars(plusminus(i,1),geostd(data.OutStdOfMeans(which,idx,high)));
    stdplusminus(i,2,:) = geo_error_bars(plusminus(i,2),geostd(data.OutStdOfMeans(which,idx,low)));
end

margin = 0.2;
% First, the ratios plot
ymin = min(1,10.^(round((log10(min(ratio-stdratio(:,:,1)))-margin)*10)/10));
ymax = round(10.^(round((log10(max(ratio+stdratio(:,:,2)))+margin)*10)/10));

h = figure('PaperPosition',figsize);
barwitherr(stdratio,ratio);
set(gca,'XTickLabel',{dataset{:,1}});
set(gca,'YSCale','log');
ylim([ymin ymax]); xlim([0 n_conditions]+0.5);
ylabel('\pm Ratio of Means');
title([OS.Description ' Ratios']);
outputfig(h,[OS.StemName '-' OS.DeviceName '-' 'plusminus-ratios-bar'],OS.Directory);

% Second, the absolutes plot
ymin = 10.^(round((log10(min(min(plusminus-stdplusminus(:,:,1))))-margin)*10)/10);
ymax = round(10.^(round((log10(max(max(plusminus+stdplusminus(:,:,2))))+margin)*10)/10));

h = figure('PaperPosition',figsize);
barwitherr(stdplusminus,plusminus);
set(gca,'XTickLabel',{dataset{:,1}});
set(gca,'YSCale','log');
ylim([ymin ymax]); xlim([0 n_conditions]+0.5);
ylabel('Output MEFL');
title([OS.Description]);
outputfig(h,[OS.StemName '-' OS.DeviceName '-' 'plusminus-bar'],OS.Directory);

if ~isempty(OS.csvfile)
    if isa(OS.csvfile,'char'), csvfid = fopen(OS.csvfile,'w+');
    else csvfid = OS.csvfile;
    end
    
    fprintf(csvfid,[OS.Description '\n']);
    fprintf(csvfid,'Condition,Plus Count,Minus Count,Plus Mean,-2 std.dev,+2 std.dev,Minus Mean,-2 std.dev,+2 std.dev\n');
    for i=1:size(dataset,1),
        fprintf(csvfid,'%s,%i,%i,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n',dataset{i,1}, ...
            counts(i,1),counts(i,2),...
            plusminus(i,1),stdplusminus(i,1,1),stdplusminus(i,1,2), ...
            plusminus(i,2),stdplusminus(i,2,1),stdplusminus(i,2,2));
    end
    fprintf(csvfid,'\n');
    fprintf(csvfid,'Condition,+/- Ratio,-2 std.dev.,+2 std.dev\n');
    for i=1:size(dataset,1),
        fprintf(csvfid,'%s,%.3f,%.3f,%.3f\n',dataset{i,1},ratio(i),stdratio(i,1,1),stdratio(i,1,2));
    end
    fprintf(csvfid,'\n\n');
end
