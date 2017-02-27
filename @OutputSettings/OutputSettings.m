% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

%OUTPUTSETTINGS Summary of this class goes here
%   Detailed explanation goes here    
function OS = OutputSettings(StemName, DeviceName, Description, Directory, FigureSize)
    OS.StemName='';
    OS.DeviceName='';
    OS.Description='';
    OS.Directory='./'; % Default is current directory (might be wrong for windows)
    OS.FixedInducerAxis = [];      % fixed -> [min max]
    OS.FixedInputAxis =   [];      % fixed -> [min max]
    OS.FixedNormalizedInputAxis =   [];      % fixed -> [min max]
    OS.FixedOutputAxis =  [];      % fixed -> [min max]
    OS.FixedNormalizedOutputAxis =  [];      % fixed -> [min max]
    OS.FixedXAxis = [];             % fixed -> [min max]
    OS.FixedYAxis = [];             % fixed -> [min max]
    OS.ColorPlots = true;
    OS.PlotPopulation = true;
    OS.PlotNormalized = true;
    OS.PlotNonnormalized = true;
    OS.PlotEveryN = 1;
    OS.PlotTickMarks = false;
    OS.FigureSize = [];
    OS.csvfile = []; % may be either an fid or a string

    if nargin > 0
        OS.StemName = StemName;
        OS.DeviceName = DeviceName;
        OS.Description = Description;
        if nargin > 3, OS.Directory = Directory; end
        if nargin > 4, OS.FigureSize = FigureSize; end
    end;
  %FY: I intentionally commented out the following class statement. 
  %There is method for this class thus it is as good as a struct.
  
  %OS=class(OS,'OutputSettings');  
    
    
    
