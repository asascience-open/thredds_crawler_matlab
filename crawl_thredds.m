function data = crawl_thredds(varargin)
%--------------------------------------------------------------------------
% function crawl_thredds
%
%   Inputs:
%       url = URL to the thredds data server you'd like to crawl
%       extension = extension of data files you want to open (.nc for now)
%   Outputs:
%       data = Matlab structure with the following fields:
%                 id - Dataset ID
%                 name - Dataset name
%                 catalog_url - Dataset url
%--------------------------------------------------------------------------
global DEBUG_PLOTS DOWNLOAD_DATA datasets

DEBUG_PLOTS = false;
DOWNLOAD_DATA = false;

if ~isfield(datasets,'id')
    datasets.id = {};
    datasets.name = {};
    datasets.metadata = {};
    datasets.catalog_url = {};
end

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
    crawl_thredds(dataurl);
end

% Get the datasets
allItems = tree.getElementsByTagName('dataset');
for k = 0:allItems.getLength-1
    thisItem = allItems.item(k);
    dataset = thisItem.getAttribute('name');
    dataurl = [url char(dataset)];
    if strcmp(dataurl(end-2:end),ext)
        disp('-------------------------------------------------------------')
        disp(['Opening ' dataurl '.....'])
        check_nc_file(dataurl)
        disp('-------------------------------------------------------------')
        dataid = thisItem.getAttribute('ID');
        leaf_url = [url 'catalog.xml?dataset=' char(dataid)];
        datasets = leaf_dataset(datasets, leaf_url);
        
    else
        disp(['skipping ' char(dataset)]);
    end
end

data = datasets;


function datasets = leaf_dataset(datasets, leaf_url)

tree = xmlread(leaf_url);
allItems = tree.getElementsByTagName('dataset');
for k = 0:allItems.getLength-1
    thisItem = allItems.item(k);
    datasets.name{end+1} = char(thisItem.getAttribute('name'));
    datasets.id{end+1} = char(thisItem.getAttribute('ID'));
%     datasets{end+1}.metadata = 
    C = strsplit(leaf_url,'?');
    datasets.catalog_url{end+1} = C{1};
end

function check_nc_file(dataurl)
global DEBUG_PLOTS DOWNLOAD_DATA
try
    ncid = netcdf.open(dataurl,'NC_NOWRITE');
    
    % Get all the variable names
    [~,nvars] = netcdf.inq(ncid);
    variable_names = cell(nvars,1);
    for n = 0:nvars-1
        variable_names{n+1} = netcdf.inqVar(ncid,n);
    end
    
    % Read in time (if available)
    if any(ismember(variable_names,'time'))
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
    %         xticklabel_rotate([],45);
            [~, filename] = fileparts(dataurl);
            title_str = strrep(filename, '_', '-');
            title(title_str)
    %         close(fig)
        end
    else
        disp('Could not find variable named time!')
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