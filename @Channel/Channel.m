% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.


% name
% Laser
% FilterSpec
% facs name, filter and laser which will be used for equivalance
% checking
% 'pseudo' marker is used for internal use when the controls were
% not correct, but the data is being used anyway (e.g., for early
% trials of a method
function C = Channel(name, laser, filterC, filterW, pseudo)
    if nargin == 0 
        C.name ='';
        C.Laser = 0;
        C.FilterCenter = 0;
        C.FilterWidth = 0;
        C.PseudoUnits = 0;
    elseif nargin >= 4
        C.name = name;
        C.Laser = laser;
        C.FilterCenter = filterC;
        C.FilterWidth = filterW;
        if nargin >= 5
            C.PseudoUnits = pseudo;
        else
            C.PseudoUnits = 0;
        end
        % Warn if we're seeing unspecified channels
        if(C.Laser==0 || C.FilterCenter==0 || C.FilterWidth==0),
            warning('Model:Color','Channel %s has unspecified laser and/or filter.  Unspecified channels may be confused together.',C.name);
        end
    end
    
    C.description = []; % file descriptor: will get filled in by colormodel resolution
    C.LineSpec='';
    C.PrintName='';
    C=class(C,'Channel');


