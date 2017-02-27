% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed 
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function data = readfcs_compensated_MEFL(CM,filename,with_AF,floor)
    if(CM.initialized<1), error('Cannot read MEFL: ColorModel not yet resolved'); end; % ensure initted
    
    % Read to arbitrary units
    audata = readfcs_compensated_au(CM,filename,with_AF,floor);
    % Translate each channel to FITC
    FITCdata = zeros(size(audata));
    for i=1:numel(CM.Channels)
        FITCdata(:,i) = translate(CM.color_translation_model,audata(:,i),CM.Channels{i},CM.FITC_channel);
    end
    % Translate FITC AU to MEFLs
    k_MEFL= getK_MEFL(CM.unit_translation);
    data = FITCdata*k_MEFL;
    
