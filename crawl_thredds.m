function crawl_thredds(varargin)
%--------------------------------------------------------------------------
% function crawl_frf_thredds
%
%   Inputs:
%       url = URL to the thredds data server you'd like to crawl
%       extension = extension of data files you want to open (.nc for now)
%
%--------------------------------------------------------------------------
global DEBUG_PLOTS DOWNLOAD_DATA

DEBUG_PLOTS = false;
DOWNLOAD_DATA = false;

url = 'http://usace.asa.rocks/thredds/dodsC/frfData/oceanography/waves/waverider632/catalog.html';
ext = '.nc';

if nargin >= 1
    url = varargin{1};
end
if nargin >= 2
    ext = varargin{2};
end

url = strrep(url, 'catalog.html', 'catalog.xml');
try
    tree = xmlread(url);
catch ME
    error_msg = getReport(ME,'extended','hyperlinks','off');
    disp(error_msg)
    return
end

stripped_url = strsplit(url, 'catalog.xml');
url = stripped_url{1};

% Crawl the catalog refs
allItems = tree.getElementsByTagName('catalogRef');
for k = 0:allItems.getLength-1
    thisItem = allItems.item(k);
    href = thisItem.getAttribute('xlink:title');
%     disp(char(dataset));
    dataurl = [url char(href) '/catalog.html'];
    crawl_thredds(dataurl)
end

% Get the datasets
allItems = tree.getElementsByTagName('dataset');
for k = 0:allItems.getLength-1
    thisItem = allItems.item(k);
    dataset = thisItem.getAttribute('name');
    dataurl = [url char(dataset)];
    if strcmp(dataurl(end-2:end),ext)
        disp(['Opening ' dataurl '.....'])
        check_nc_file(dataurl)
        disp('-------------------------------------------------------------')
    else
        disp(['skipping ' char(dataset)]);
    end
end

function check_nc_file(dataurl)
global DEBUG_PLOTS DOWNLOAD_DATA
try
    ncid = netcdf.open(dataurl,'NC_NOWRITE');
    % Read in time
    time_id = netcdf.inqVarID(ncid, 'time');
    time = netcdf.getVar(ncid, time_id);
    time = time/86400 + datenum(1970,1,1);

    if DEBUG_PLOTS
        fig = figure();
        % Now read a variable
        nc_var_id = netcdf.inqVarID(ncid, 'waveHs');
        nc_var = netcdf.getVar(ncid, nc_var_id);
        plot(time, nc_var(:), 'LineWidth', 2)
        datetick('x',29,'keepticks')
        % xticklabel_rotate is a separate function!
        xticklabel_rotate([],45);
        [~, filename] = fileparts(dataurl);
        title_str = strrep(filename, '_', '-');
        title(title_str)
%         close(fig)
    end
    if DOWNLOAD_DATA
        % Read all the variables and attributes and write a local
        % copy

    end
    netcdf.close(ncid)
    disp('Success!')
catch ME
    error_msg = getReport(ME,'extended','hyperlinks','off');
    disp(error_msg)
    if exist('ncid','var')
        netcdf.close(ncid)
    end
end