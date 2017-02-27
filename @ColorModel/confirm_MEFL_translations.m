function [ok CM] = confirm_MEFL_translations(CM)
% Checks to see that all channels can be translated to MEFL

% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed 
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

    scales = getScales(CM.color_translation_model);
    ok = true;
    fi = indexof(CM.Channels,CM.FITC_channel);
    for i=1:numel(CM.Channels)
        if(i==fi) continue; end;
        if(isnan(scales(i,fi))), 
            ok = false;
            warning('Model:Color','No pairwise translation for %s to %s; using pseudoMEFL',getPrintName(CM.Channels{i}),getPrintName(CM.FITC_channel));
            scales(i,fi) = 1;
            CM.Channels{i} = setIsPseudo(CM.Channels{i},1);
            
            % pseudo-MEFLize channel
            AFMi = CM.autofluorescence_model{i};
            k_MEFL=getK_MEFL(CM.unit_translation);
            CM.autofluorescence_model{i}=MEFLize(AFMi,scales(i,fi),k_MEFL);
        end
    end
    
    % if FITC channel is pseudo (e.g., becaus of missing beads), then make all channels pseudo
    if(isPseudo(CM.FITC_channel)),
        warning('Model:Color','FITC channel is pseudo, so all other channels are pseudo as well');
        for i=1:numel(CM.Channels),
            CM.Channels{i} = setIsPseudo(CM.Channels{i},1);
        end
    end
    
    if ~ok,
        warning('Model:Color','Not all channels can be translated to standard MEFL units.');
        CM.color_translation_model = setScales(CM.color_translation_model,scales);
    end
