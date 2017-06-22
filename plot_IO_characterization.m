% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function plot_IO_characterization(results,outputsettings,in_channel,out_channel)
if nargin<3, in_channel = 'input'; end;
if nargin<4, out_channel = 'output'; end;

step = outputsettings.PlotEveryN;
ticks = outputsettings.PlotTickMarks;

AP = getAnalysisParameters(results);
n_bins = get_n_bins(getBins(AP));
hues = (1:n_bins)./n_bins;
fa = getFractionActive(results);

[input_mean] = get_channel_results(results,in_channel);
[output_mean output_std] = get_channel_results(results,out_channel);
in_units = getChannelUnits(AP,in_channel);
out_units = getChannelUnits(AP,out_channel);

%%% I/O plots:
% Plain I/O plot:
h = figure('PaperPosition',[1 1 5 3.66]);
set(h,'visible','off');
for i=1:step:n_bins
    which = fa(i,:)>getMinFractionActive(AP);
    loglog(input_mean(i,which),output_mean(i,which),'-','Color',hsv2rgb([hues(i) 1 0.9])); hold on;
    if ticks
        loglog(input_mean(i,which),output_mean(i,which),'+','Color',hsv2rgb([hues(i) 1 0.9]));
    end
    loglog(input_mean(i,which),output_mean(i,which).*output_std(i,which),':','Color',hsv2rgb([hues(i) 1 0.9]));
    loglog(input_mean(i,which),output_mean(i,which)./output_std(i,which),':','Color',hsv2rgb([hues(i) 1 0.9]));
end;
%if(outputSettings.FixedAxis), axis([1e2 1e10 1e2 1e10]); end;
xlabel(['IFP ' in_units]); ylabel(['OFP ' out_units]);
set(gca,'XScale','log'); set(gca,'YScale','log');
if(outputsettings.FixedInputAxis), xlim(outputsettings.FixedInputAxis); end;
if(outputsettings.FixedOutputAxis), ylim(outputsettings.FixedOutputAxis); end;
title(['Raw ',outputsettings.StemName,' transfer curve, colored by constitutive bin']);
outputfig(h,[outputsettings.StemName,'-',outputsettings.DeviceName,'-mean'],outputsettings.Directory);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plasmid system is disabled, due to uncertainty about correctness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Normalized plot color by plasmid count:
% h = figure('PaperPosition',[1 1 5 3.66]);
% set(h,'visible','off');
% for i=1:step:n_bins
%     pe=getPlasmidEstimates(results);
%     which = fa(i,:)>0.9;
%     loglog(input_mean(i,which),output_mean(i,which)./pe(i,which),'-','Color',hsv2rgb([hues(i) 1 0.9])); hold on;
%     if ticks
%         loglog(input_mean(i,which),output_mean(i,which)./pe(i,which),'+','Color',hsv2rgb([hues(i) 1 0.9]));
%     end
%     loglog(input_mean(i,which),output_mean(i,which)./pe(i,which).*output_std(i,which),':','Color',hsv2rgb([hues(i) 1 0.9]));
%     loglog(input_mean(i,which),output_mean(i,which)./pe(i,which)./output_std(i,which),':','Color',hsv2rgb([hues(i) 1 0.9]));
% end;
% %if(outputSettings.FixedAxis), axis([1e2 1e10 1e2 1e10]); end;
% set(gca,'XScale','log'); set(gca,'YScale','log');
% xlabel(['IFP ' in_units]); ylabel(['OFP ' out_units '/plasmid']);
% if(outputsettings.FixedNormalizedInputAxis), xlim(outputsettings.FixedNormalizedInputAxis); end;
% if(outputsettings.FixedNormalizedOutputAxis), ylim(outputsettings.FixedNormalizedOutputAxis); end;
% title(['Normalized ',outputsettings.DeviceName,' transfer curve, colored by plasmid count']);
% outputfig(h,[outputsettings.StemName,'-',outputsettings.DeviceName,'-mean-norm'],outputsettings.Directory);

end
