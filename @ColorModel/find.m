% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed 
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function index = find(CM, channel)
    found=false;
    for i=1:numel(CM.Channels)
        if(CM.Channels{i} == channel)
            index = i; found = true; break;
        end;
    end;
    if(~found), error('Unable to find channel %s',getName(channel)); end;

        
