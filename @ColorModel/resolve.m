% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed 
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function CM=resolve(CM, settings, path) % call after construction and configuration

if (nargin < 3)
    path = getSetting(settings, 'path', './');
end

    % fill in channel descriptors from designated file (default = beadfile)
    if hasSetting(settings,'channel_template_file'), 
        template = getSetting(settings,'channel_template_file'); 
    else template = CM.BeadFile; 
    end;
    [fcsdat fcshdr] = fca_readfcs(template);
    % Remember channel descriptions, for later confirmation
    for i=1:numel(CM.Channels),
        [ignored desc] = get_fcs_color(fcsdat,fcshdr,getName(CM.Channels{i}));
        CM.Channels{i} = setDescription(CM.Channels{i},desc);
        % TODO: figure out how to add FSC and SSC channel descriptions (used by filters) for confirmation
    end
    
    % build model
    % First, unit translation from beads
    if hasSetting(settings,'override_units')
        k_MEFL = getSetting(settings,'override_units');
        CM.unit_translation = UnitTranslation('Specified',k_MEFL,[],[],{});
        warning('TASBE:ColorModel','Warning: overriding units with specified k_MEFL value of %d',k_MEFL);
    else
        CM.unit_translation = beads_to_mefl_model(CM,settings,CM.BeadFile, 2, path);
    end
    
    % Next, autofluorescence and compensation model
    CM.autofluorescence_model = computeAutoFluorescence(CM,settings, path);
    if hasSetting(settings,'override_compensation')
        matrix = getSetting(settings,'override_compensation');
        warning('TASBE:ColorModel','Warning: overriding compensation model with specified values.');
        CM.compensation_model = LinearCompensationModel(matrix, zeros(size(matrix)));
    else
        CM.compensation_model = computeColorCompensation(CM,settings);
    end
    CM.initialized = 0.5; % enough to read in AU
    if CM.compensation_plot, plot_compensated_controls(CM,settings); end;
    
    % finally, color translation model
    if hasSetting(settings,'override_translation')
        scales = getSetting(settings,'override_translation');
        color_translation_model = ColorTranslationModel(CM.Channels,scales);
        for i=1:numel(CM.Channels),
            if(CM.Channels{i}==CM.FITC_channel) i_fitc = i; end;
        end
        for i=1:numel(CM.Channels),
            if(CM.Channels{i}==CM.FITC_channel) continue; end;
            AFMi = CM.autofluorescence_model{i};
            k_MEFL=getK_MEFL(CM.unit_translation);
            CM.autofluorescence_model{i}=MEFLize(AFMi,scales(i,i_fitc),k_MEFL);
        end
        warning('TASBE:ColorModel','Warning: overriding translation scaling with specified values.');
    else
        [color_translation_model CM] = computeColorTranslations(CM, settings);
    end
    CM.color_translation_model = color_translation_model;
    CM.initialized = 1; % enough to read in (pseudo)MEFL
    
    %if ~confirm_MEFL_translations(CM), return; end;% if can't translate all to MEFL, then warn and stop here
    [ok CM] = confirm_MEFL_translations(CM);% warn if can't translate all to MEFL
    
    CM.noise_model = computeNoiseModel(CM,settings);
    
