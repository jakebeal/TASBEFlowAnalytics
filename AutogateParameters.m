% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.
%
% ANALYSISPARAMETERS Parameters that are necessary for analysis of experiment

function AGP = AutogateParameters()

AGP.deviations = 2.0;   % Number of standard deviations within which data is selected
AGP.tightening = 0.0;   % Amount that selected components are further tightened (range: [0,1]
AGP.k_components = 2;    % number of gaussian components searched for
AGP.channel_names = {'FSC-A','SSC-A','FSC-H','FSC-W','SSC-H','SSC-W'};
AGP.fraction = 0.95;    % Fraction of range considered saturated and thus excluded from computation
AGP.selected_components = [];
% Display:
AGP.show_nonselected = true;
AGP.visible = false;
AGP.largeoutliers = true;
AGP.range = [];
AGP.density = 1;
