function linelabel(state,ind)
%linelabel       Identify a plotted line by clicking on it.
%
% Application: Sometimes a legend just isn't good enough.
% With linelabel, clicking on a line labels it.  
%
%   LINELABEL turns on line labels for the lines in the current axis.
%   LINELABEL(handles) turns on line labels for the lines
%     specified in handles.  handles is a vector of handles
%     to line objects.  Lines are labeled by index (the first
%     line in handles is 1, the next is 2, ...)
%   LINELABEL(handles,[id_vector]) specifies numerical IDs for the lines.
%     id_vector must be the same length as handles
%   LINELABEL(handles,{id_cell}) specifies textual IDs for the lines
%     id_cell must be the same length as handles
%   LINELABEL(handles,'legend') Uses the labels specified in the legend
%   LINELABEL OFF turns line labeling off for the current figure
%
%	  Example: 
%       %NOTE: Interact with your plot after each call to linelabel
% 		s = sin(2*pi*linspace(0,1)')*(1:1:5);
% 		lh = plot(s);
% 		linelabel(lh)   %Number with index.
%        %Click on lines to label values.
%        %Click and drag to move label
%        %Right click to delete.
% 		linelabel off
%        %Existing line labels are locked in place; can't add more
% 		linelabel(lh,11:15)     %Provide your own numbers
% 		linelabel(lh,{'michelle','writes','useful','MATLAB','utilities'})
%                               %Provide your own custom labels
% 		legend({'Ch1','Ch2','Ch3','Ch4','Ch5'})
% 		linelabel(lh,'legend')  %Automatically use the labels from the legend.
%
%  See also DATALABEL
%  

% Written by Michelle Hirsch
% mhirsch@mathworks.com
% Copyright 2002-2014 The MathWorks, Inc

%Option: if no input arguments, add indexed labels to the
% lines in the current axis.
if nargin==0
    state = flipud(findobj(gca,'Type','line'));
    %Find lines.  Flip, since findobj returns in reverse order.
end;


if ~isstr(state) % Set the WindowButtonDownFcn (turn on linelabel)
    %User call: specify handles to lines
    handles = state;
    if ~all(ishandle(handles))
        error('Input argument must be a vector of line handles');
    end;
    
    set(gcf,'WindowButtonDownFcn','linelabel down')
    set(gcf,'DoubleBuffer','on');       %eliminate flicker
    
    %Store identity to each line as appdata
    %There are four possibilities here:
    %1.  User doesn't specify anything (1 nargin).  Use 1:length(handles)
    %2.  User specifies a vector.  Use these.  arg2 = vector
    %3.  User specifies a cell array of strings.  arg2 = cell aray
    %3.  User says to use the labels in the legend.  arg2 = 'legend'
    %Regardless, end up with a cell array of strings.  Assign one 
    %  value to each handle, in order
    
    if nargin<2        %1.  User doesn't specify anything 
        ind = mat2cell(num2str((1:length(handles))'),ones(length(handles),1)); 
        
    elseif strcmp(ind,'legend')
        %Find the legend.
        %First, look for all legends on this figure
        
        current_axis = get(handles(1),'Parent');
        current_figure = ancestor(current_axis,'figure');
        
        legh = findobj(current_figure,'Tag','legend');
        if isempty(legh)
            error('Sorry, but you must have a legend to use this syntax.')
        end;
        
        % figure out which legend belongs to our axes
        if verLessThan('matlab','8.4')  % Original graphics system
            % In original graphics system, legend was implemented as an
            % axes. All of the interesting legend bits were stored in a
            % struct in user data.
            
            ud = get(legh,'UserData');  
            
            % If we got more than one legend, pick the right one
            if iscell(ud)       % 2 or more legends returns a cell of structs
                
                %Search through these to find the one belonging to our axes
                found=0;
                ii=0;
                while ~found
                    ii=ii+1;
                    if ud{ii}.PlotHandle == current_axis
                        found=1;
                        ud = ud{ii};
                    end;
                end;
            end
            
            ind = ud.lstrings;  % The legend strings

        else    % New graphics system introduced in R2014b (MATLAB 8.4)
            % In the new graphics system, legends are first class objects.
            associated_axes = [legh.Axes];
            axind = find(associated_axes == current_axis);
            
            if isempty(axind)
                error('Sorry, but I can''t find a legend associated with the axes containing these lines.')
            end
                        
            ind = legh(axind).String;
        end
        

        %Ensure that the legend had one entry per handle
        if length(ind) ~= length(handles)
            error('Legend must have same number of entries as the input handle vector.');
        end;
        
        
    elseif ~iscell(ind)     %2.  User specifies a vector.
        %Check to be sure that index vector is same length as handles
        if length(ind) ~= length(handles)
            error('Index vector must be of same length as handle vector');
        end;
        
        ind = mat2cell(num2str(ind(:)),ones(length(handles),1));
        
    else                    %3.  User specifies a cell array of strings
        if length(ind) ~= length(handles)
            error('Index cell array must be of same length as handle vector');
        end;
    end;
    
    for ii=1:length(handles)
        setappdata(handles(ii),'Index',ind{ii});
    end;
    
elseif strcmp(state,'down') % Execute the WindowButtonDownFcn.  Add label
    htype = get(gco,'Type');
    tag = get(gco,'Tag');
    
    if strcmp(htype,'line')      %Line - Add text object
        
        %User-selected point
        cp = get(gca,'CurrentPoint');
        x = cp(1,1);       %first xy values
        y = cp(1,2);       %first xy values
        
        
        %Which line is this?
        lineno = getappdata(gco,'Index');
        th = text(x,y,lineno,'HorizontalAlignment','center');
        
        %Set background color of label.  MATLAB 6.5 or higher.
        v=ver('MATLAB');
        v=str2num(v.Version(1:3));
        if v>=6.5
            set(th,'BackgroundColor','y');
        end;
        
        
        mh = uicontextmenu('Tag','DeleteObject', ...
            'Callback','delete(gco);');
        
        set(th,'UIContextMenu',mh);
        
    elseif strcmp(htype,'text')     %Clicked on label - switch to moving
        set(gcf,'WindowButtonMotionFcn','linelabel move', ...
            'WindowButtonUpFcn','linelabel up');
    end
    
elseif strcmp(state,'move') % Execute the WindowButtonMotionFcn. move label
    htype = get(gco,'Type');
    tag = get(gco,'Tag');
    if ~isempty(gco)
        
        th = gco;
        
        cp = get(gca,'CurrentPoint');
        pt = cp(1,[1 2]);
        
        x = cp(1,1);       %first xy values
        y = cp(1,2);       %first xy values
        
        set(th,'Position', [x y 0])
        
        drawnow
    end;
elseif strcmp(state,'up') % Execute the WindowButtonUpFcn
    htype = get(gco,'Type');
    tag = get(gco,'Tag');
    if strcmp(htype,'text')
        set(gcf,'WindowButtonMotionFcn','')
    end;
elseif strcmp(state,'off') % Unset the WindowButton...Fcns
    set(gcf,'WindowButtonDownFcn','','WindowButtonUpFcn','')
end
