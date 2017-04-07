function [fcsdat, fcshdr, fcsdatscaled] = fca_readfcs(filename,clip_events)
% [fcsdat, fcshdr, fcsdatscaled] = fca_readfcs(filename);
%
% Read FCS 2.0 and FCS 3.0 type flow cytometry data file and put the list mode  
% parameters to the fcsdat array with size of [NumOfPar TotalEvents]. 
% Some important header data are stored in the fcshdr structure:
% TotalEvents, NumOfPar, starttime, stoptime and specific info for parameters
% as name, range, bitdepth, logscale(yes-no) and number of decades.
%
% [fcsdat, fcshdr] = fca_readfcs;
% Without filename input the user can select the desired file
% using the standard open file dialog box.
%
% [fcsdat, fcshdr, fcsdatscaled] = fca_readfcs(filename);
% Supplying the third output the fcsdatscaled array contains the scaled     
% parameters. It might be useful for logscaled parameters, but no effect 
% in the case of linear parameters. The log scaling is the following
% operation for the "ith" parameter:  
% fcsdatscaled(:,i) = ...
%   10.^(fcsdat(:,i)/fcshdr.par(i).range*fcshdr.par(i).decade;);

% Ver 2.5
% 2006-2009 / University of Debrecen, Institute of Nuclear Medicine
% Laszlo Balkay 
% balkay@pet.dote.hu
%
% 14/08/2006 I made some changes in the code by the suggestion of 
% Brian Harms <brianharms@hotmail.com> and Ivan Cao-Berg <icaoberg@cmu.edu> 
% (given at the user reviews area of Mathwork File exchage) The program should work 
% in the case of Becton EPics DLM FCS2.0, CyAn Summit FCS3.0 and FACSDiva type 
% list mode files.
%
% 29/01/2008 Updated to read the BD LSR II file format and including the comments of
% Allan Moser (Cira Discovery Sciences, Inc.)
%
% 24/01/2009 Updated to read the Partec CyFlow format file. Thanks for
% Gavin A Price
% 
% Further updated by Jacob Beal, 2010 - 2017

% if noarg was supplied
if nargin == 0
     [FileName, FilePath] = uigetfile('*.*','Select fcs2.0 file');
     filename = [FilePath,FileName];
     if FileName == 0;
          fcsdat = []; fcshdr = [];
          return;
     end
else
    filecheck = dir(filename);
    if size(filecheck,1) == 0
        hm = msgbox([filename,': The file does not exist!'], ...
            'FcAnalysis info','warn');
        fcsdat = []; fcshdr = [];
        return;
    end
end
if nargin<2, clip_events = 1e6; end;

% if filename arg. only contain PATH, set the default dir to this
% before issuing the uigetfile command. This is an option for the "fca"
% tool
[FilePath, FileNameMain, fext] = fileparts(filename);
FilePath = [FilePath filesep];
FileName = [FileNameMain, fext];
if  isempty(FileNameMain)
    currend_dir = cd;
    cd(FilePath);
    [FileName, FilePath] = uigetfile('*.*','Select FCS file');
     filename = [FilePath,FileName];
     if FileName == 0;
          fcsdat = []; fcshdr = [];
          return;
     end
     cd(currend_dir);
end

%fid = fopen(filename,'r','ieee-be');
fid = fopen(filename,'r','b');
fcsheader_1stline   = fread(fid,64,'char');
fcsheader_type = char(fcsheader_1stline(1:6)');
%
%reading the header
%
if strcmp(fcsheader_type,'FCS1.0')
    hm = msgbox('FCS 1.0 file type is not supported!','FcAnalysis info','warn');
    fcsdat = []; fcshdr = [];
    fclose(fid);
    return;
elseif  strcmp(fcsheader_type,'FCS2.0') || strcmp(fcsheader_type,'FCS3.0') || strcmp(fcsheader_type,'FCS3.1') % FCS2.0 or FCS3.0 or FCS3.1 types
    if(strcmp(fcsheader_type,'FCS3.1')),
        % To get rid of these warnings, do: warning('off','FCS:Read31');
        %warning('FCS:Read31','FCS3.1 support is experimental'); 
        %warning('FCS:Read31','FCS3.1 reading does not handle: $PnL with multiple lasers, $PnN non-required values, $PnD parameters, sample volume with $VOL, dataset originality, plate/well identifiers');
    end;
    fcshdr.fcstype = fcsheader_type;
    FcsHeaderStartPos   = str2num(char(fcsheader_1stline(16:18)'));
    FcsHeaderStopPos    = str2num(char(fcsheader_1stline(19:26)'));
    FcsDataStartPos     = str2num(char(fcsheader_1stline(27:34)'));
    status = fseek(fid,FcsHeaderStartPos,'bof');
    fcsheader_main = fread(fid,FcsHeaderStopPos-FcsHeaderStartPos+1,'char');%read the main header
    warning off MATLAB:nonIntegerTruncatedInConversionToChar;
    fcshdr.filename = FileName;
    fcshdr.filepath = FilePath;
    % "The first character of the primary TEXT segment contains the
    % delimiter" (FCS standard)
    if fcsheader_main(1) == 12
        mnemonic_separator = 'FF';
    else
        mnemonic_separator = char(fcsheader_main(1));
    end
    if mnemonic_separator == '@';% WinMDI
        hm = msgbox([FileName,': The file can not be read (Unsupported FCS type: WinMDI histogram file)'],'FcAnalysis info','warn');
        fcsdat = []; fcshdr = [];
        fclose(fid);
        return;
    end
    fcshdr.TotalEvents = str2num(get_mnemonic_value('$TOT',fcsheader_main, mnemonic_separator));
    fcshdr.NumOfPar = str2num(get_mnemonic_value('$PAR',fcsheader_main, mnemonic_separator));
    fcshdr.Creator = get_mnemonic_value('CREATOR',fcsheader_main, mnemonic_separator);
    for i=1:fcshdr.NumOfPar
        fcshdr.par(i).name = get_mnemonic_value(['$P',num2str(i),'N'],fcsheader_main, mnemonic_separator);
        fcshdr.par(i).rawname = fcshdr.par(i).name;
        fcshdr.par(i).range = str2num(get_mnemonic_value(['$P',num2str(i),'R'],fcsheader_main, mnemonic_separator));
        fcshdr.par(i).bit = str2num(get_mnemonic_value(['$P',num2str(i),'B'],fcsheader_main, mnemonic_separator));

        %%%%
        % Pick up additional (optional) parameters: - JSB
        %%%%
        % $PnV Detector voltage for parameter n.
        fcshdr.par(i).voltage = get_mnemonic_value(['$P',num2str(i),'V'],fcsheader_main, mnemonic_separator);
        if(fcshdr.par(i).voltage), fcshdr.par(i).voltage = str2num(fcshdr.par(i).voltage); end;
        % $PnF Name of optical filter for parameter n.
        fcshdr.par(i).filter = get_mnemonic_value(['$P',num2str(i),'F'],fcsheader_main, mnemonic_separator);
        % $PnG Amplifier gain used for acquisitionof parameter n.
        fcshdr.par(i).gain = get_mnemonic_value(['$P',num2str(i),'G'],fcsheader_main, mnemonic_separator);
        if(fcshdr.par(i).gain), fcshdr.par(i).gain = str2num(fcshdr.par(i).gain); end;
        % $PnL Excitation wavelength for parameter n.
        fcshdr.par(i).emitter_wavelength = get_mnemonic_value(['$P',num2str(i),'L'],fcsheader_main, mnemonic_separator);
        if(fcshdr.par(i).emitter_wavelength), fcshdr.par(i).emitter_wavelength = str2num(fcshdr.par(i).emitter_wavelength); end;
        % $PnO Excitation power for parameter n.
        fcshdr.par(i).emitter_power = get_mnemonic_value(['$P',num2str(i),'O'],fcsheader_main, mnemonic_separator);
        if(fcshdr.par(i).emitter_power), fcshdr.par(i).emitter_power = str2num(fcshdr.par(i).emitter_power); end;
        % $PnP Percent of emitted light collectedby parameter n.
        fcshdr.par(i).percent_light = get_mnemonic_value(['$P',num2str(i),'P'],fcsheader_main, mnemonic_separator);
        if(fcshdr.par(i).percent_light), fcshdr.par(i).percent_light = str2num(fcshdr.par(i).percent_light); end;
        % $PnT Detector type for parameter n.
        fcshdr.par(i).detector = get_mnemonic_value(['$P',num2str(i),'T'],fcsheader_main, mnemonic_separator);
        %%% not using these:
        % $Pkn Peak channel number of univariatehistogram for parameter n.
        % $PKNn Count in peak channel of univariatehistogram for parameter n.
        % $PnS Name used for parameter n.
        replacename = get_mnemonic_value(['$P',num2str(i),'S'],fcsheader_main, mnemonic_separator);
        % Replace name if nickname is present and not just whitespace
        if(numel(replacename)>0 && ~isempty(find(~isspace(replacename), 1))), fcshdr.par(i).name = replacename; end;
        % FCS 3.1-only parameters:
        if(strcmp(fcsheader_type,'FCS3.1')), 
            fcshdr.par(i).calibration = get_mnemonic_value(['$P',num2str(i),'CALIBRATION'],fcsheader_main, mnemonic_separator);
        end

%==============   Changed way that amplification type is treated ---  ARM  ==================
        par_exponent_str= (get_mnemonic_value(['$P',num2str(i),'E'],fcsheader_main, mnemonic_separator));
        if isempty(par_exponent_str)
            % There is no "$PiE" mnemonic in the Lysys format
            % in that case the PiDISPLAY mnem. shows the LOG or LIN definition
            islogpar = get_mnemonic_value(['P',num2str(i),'DISPLAY'],fcsheader_main, mnemonic_separator);
            if islogpar == 'LOG'
               par_exponent_str = '5,1'; 
            else % islogpar = LIN case
                par_exponent_str = '0,0';
            end
        end
   
%         fcshdr.par(i).decade = str2num(par_exponent(1));
%         if fcshdr.par(i).decade == 0
%             fcshdr.par(i).log = 0;
%             fcshdr.par(i).logzero = 0;
%         else
%             fcshdr.par(i).log = 1;
%             if (str2num(par_exponent(3)) == 0)
%               fcshdr.par(i).logzero = 1;
%             else
%               fcshdr.par(i).logzero = str2num(par_exponent(3));
%             end
%         end
       
        par_exponent= str2num(par_exponent_str);
        fcshdr.par(i).decade = par_exponent(1);
        if fcshdr.par(i).decade == 0
            fcshdr.par(i).log = 0;
            fcshdr.par(i).logzero = 0;
        else
            fcshdr.par(i).log = 1;
            if (par_exponent(2) == 0)
              fcshdr.par(i).logzero = 1;
            else
              fcshdr.par(i).logzero = par_exponent(2);
            end
        end

        
        
%============================================================================================
    end
    fcshdr.starttime = get_mnemonic_value('$BTIM',fcsheader_main, mnemonic_separator);
    fcshdr.stoptime = get_mnemonic_value('$ETIM',fcsheader_main, mnemonic_separator);
    fcshdr.timestep = get_mnemonic_value('$TIMESTEP',fcsheader_main, mnemonic_separator);
    fcshdr.cytometry = get_mnemonic_value('$CYT',fcsheader_main, mnemonic_separator);
    fcshdr.date = get_mnemonic_value('$DATE',fcsheader_main, mnemonic_separator);
    fcshdr.byteorder = get_mnemonic_value('$BYTEORD',fcsheader_main, mnemonic_separator);
    fcshdr.datatype = get_mnemonic_value('$DATATYPE',fcsheader_main, mnemonic_separator);
    fcshdr.system = get_mnemonic_value('$SYS',fcsheader_main, mnemonic_separator);
    fcshdr.project = get_mnemonic_value('$PROJ',fcsheader_main, mnemonic_separator);
    fcshdr.experiment = get_mnemonic_value('$EXP',fcsheader_main, mnemonic_separator);
    fcshdr.cells = get_mnemonic_value('$Cells',fcsheader_main, mnemonic_separator);
    fcshdr.creator = get_mnemonic_value('CREATOR',fcsheader_main, mnemonic_separator);
else
    hm = msgbox([FileName,': The file can not be read (Unsupported FCS type)'],'FcAnalysis info','warn');
    fcsdat = []; fcshdr = [];
    fclose(fid);
    return;
end

% deal with size overflow bug for very large FCS files, in which data start gets incorrectly set to zero
% This appears to be triggered, with FACSdiva at least, when the FCS file is more than 100MB, which makes
% the data stop position more than 8 characters and causes it to collide with the start field.   -JSB
if FcsDataStartPos==0,
    warning('FCS:BadDataStart','FCS file has invalid data start position; guessing based on header end');
    FcsDataStartPos = FcsHeaderStopPos+6;
end

% optionally truncate events to avoid memory problems with extremely large FCS files -JSB
if fcshdr.TotalEvents>clip_events,
    warning('FCS:TooManyEvents','FCS file has more than %i events; truncating to avoid memory problems',clip_events);
    fcshdr.TotalEvents = clip_events;
end

%
%reading the events
%
status = fseek(fid,FcsDataStartPos,'bof');
if strcmp(fcsheader_type,'FCS2.0')
    if strcmp(mnemonic_separator,'\') || strcmp(mnemonic_separator,'FF')... %ordinary or FacsDIVA FCS2.0 
           || strcmp(mnemonic_separator,'/') % added by GAP 1/22/09
        if fcshdr.par(1).bit == 16
            fcsdat = uint16(fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint16')');
            if strcmp(fcshdr.byteorder,'1,2')...% this is the Cytomics data
                    || strcmp(fcshdr.byteorder, '1,2,3,4') %added by GAP 1/22/09
                fcsdat = bitor(bitshift(fcsdat,-8),bitshift(fcsdat,8));
            end
        elseif fcshdr.par(1).bit == 32
                if fcshdr.datatype ~= 'F'
                    fcsdat = (fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint32')');
                else % 'LYSYS' case
                    fcsdat = (fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'float32')');
                end
        else 
            bittype = ['ubit',num2str(fcshdr.par(1).bit)];
            fcsdat = fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],bittype, 'ieee-le')';
        end
    elseif strcmp(mnemonic_separator,'!');% Becton EPics DLM FCS2.0
        fcsdat_ = fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint16', 'ieee-le')';
        fcsdat = zeros(fcshdr.TotalEvents,fcshdr.NumOfPar);
        for i=1:fcshdr.NumOfPar
            bintmp = dec2bin(fcsdat_(:,i));
            fcsdat(:,i) = bin2dec(bintmp(:,7:16)); % only the first 10bit is valid for the parameter  
        end
    end
    fclose(fid);
elseif strcmp(fcsheader_type,'FCS3.0') || strcmp(fcsheader_type,'FCS3.1')
    if strcmp(fcsheader_type,'FCS3.0') && strcmp(mnemonic_separator,'|') % CyAn Summit FCS3.0
        fcsdat_ = (fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint16','ieee-le')');
        fcsdat = zeros(size(fcsdat_));
        new_xrange = 1024;
        for i=1:fcshdr.NumOfPar
            fcsdat(:,i) = fcsdat_(:,i)*new_xrange/fcshdr.par(i).range;
            fcshdr.par(i).range = new_xrange;
        end
    else % ordinary FCS 3.0
        if fcshdr.datatype == 'I'
            if(fcshdr.par(1).bit==32) % assume all have same bit width
                fcsdat = uint32(fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint32')');
            else if (fcshdr.par(1).bit==16)
                    fcsdat = uint32(fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint16')');
                else if(fcshdr.par(1).bit==24)
                        fcsdat = uint32(fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'bit24')');
                    else
                        error('Unsupported bit width: %d',fcshdr.par(1).bit);
                    end
                end
            end
            if strcmp(fcshdr.byteorder, '1,2,3,4')
                fcsdat = swapbytes(fcsdat);
            end
        else
            if fcshdr.datatype == 'F' % floating
                if strcmp(fcshdr.byteorder, '1,2,3,4')
                    endian = 'ieee-le';
                else
                    endian = 'ieee-be';
                end
                fcsdat = fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'float32',endian)';
            else 
                error(['Unsupported FCS 3.0 data type: ' fcshdr.datatype])
            end;
        end
    end
    fclose(fid);
end
% Ensure FCS data is ordinary floating point numbers
fcsdat = double(fcsdat);
%
%calculate the scaled events (for log scales)
%
fcsdatscaled = zeros(size(fcsdat));
if(numel(fcsdat)>0)
    for  i = 1 : fcshdr.NumOfPar
        Xlogdecade = fcshdr.par(i).decade;
        XChannelMax = fcshdr.par(i).range;
        Xlogvalatzero = fcshdr.par(i).logzero;
        if ~fcshdr.par(i).log
           fcsdatscaled(:,i)  = fcsdat(:,i);
        else
           fcsdatscaled(:,i) = Xlogvalatzero*10.^(double(fcsdat(:,i))/XChannelMax*Xlogdecade);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mneval = get_mnemonic_value(mnemonic_name,fcsheader,mnemonic_separator)

if strcmp(mnemonic_separator,'\')  || strcmp(mnemonic_separator,'!') ...
        || strcmp(mnemonic_separator,'|') || strcmp(mnemonic_separator,'@')...
        || strcmp(mnemonic_separator, '/') % added by GAP 1/22/08
    mnemonic_startpos = findstr(char(fcsheader'),mnemonic_name);
    if isempty(mnemonic_startpos)
        mneval = [];
        return;
    end
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length;
    next_slashes = findstr(char(fcsheader(mnemonic_stoppos+1:end)'),mnemonic_separator);
    next_slash = next_slashes(1) + mnemonic_stoppos;

    mneval = char(fcsheader(mnemonic_stoppos+1:next_slash-1)');
elseif strcmp(mnemonic_separator,'FF')
    mnemonic_startpos = findstr(char(fcsheader'),mnemonic_name);
    if isempty(mnemonic_startpos)
        mneval = [];
        return;
    end
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length ;
    next_formfeeds = find( fcsheader(mnemonic_stoppos+1:end) == 12);
    next_formfeed = next_formfeeds(1) + mnemonic_stoppos;

    mneval = char(fcsheader(mnemonic_stoppos + 1 : next_formfeed-1)');
end
