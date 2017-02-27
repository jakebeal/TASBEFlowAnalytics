% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed 
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function data = readfcs_compensated_au(CM,filename,with_AF,floor)
    if(CM.initialized<0.5), error('Cannot read a.u.: ColorModel not yet resolved'); end; % ensure initted

    % Acquire initial data, discarding likely contaminated portions
    [rawfcs fcshdr] = read_filtered_au(CM,filename);

    [rawdata channel_desc] = select_channels(CM.Channels,rawfcs,fcshdr);
    
    % check if voltages are identical to those of the color model, warn if otherwise
    ok = true;
    for i=1:numel(CM.Channels),
        ok = ok & confirm_channel(CM.Channels{i},channel_desc{i});
    end
    if(~ok), warning('TASBE:ReadFCS','File %s does not match color model',filename); end;
    
    % Check to make sure not too many negative values:
    for i=1:numel(CM.Channels)
        frac_neg = sum(rawdata(:,i)<0)/size(rawdata,1);
        if(frac_neg>0.60) % more than 60% subzero
            warning('TASBE:NegativeFCS','More than 60%% of channel %s negative (%.1f%%) in ''%s''',getName(CM.Channels{i}),100*frac_neg,filename);
        end
    end

    % Remove autofluorescence
    no_AF_data = zeros(size(rawdata));
    for i=1:numel(CM.Channels)
        no_AF_data(:,i) = rawdata(:,i)-getMean(CM.autofluorescence_model{i});
    end
    % make sure nothing's below 1, for compensation and geometric statistics
    % (compensation can be badly thrown off by negative values)
    if(floor), no_AF_data(no_AF_data<1) = 1; end
    % Compensate for spectral bleed
    data = color_compensate(CM.compensation_model,no_AF_data);
    % Return autofluorescence, if desired
    if(with_AF)
        for i=1:numel(CM.Channels)
            data(:,i) = data(:,i)+getMean(CM.autofluorescence_model{i});
        end
    end
    % make sure nothing's below 1, for geometric statistics
    if(floor), data(data<1) = 1; end
    
