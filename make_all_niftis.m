% This script selects the data to be written to a NIfTI file.
clear

% Information about downloading the images can be found here:
% https://www.nlm.nih.gov/databases/download/vhp.html
%
% Set the main path to the raw images.
% The code expects unzipped .raw files to be in subfolders
% male/fullcolor/fullbody and female/fullcolor/fullbody.
VH_data_main = 'E:\VH_data';

% Load the CSV-file with the metadata for selected sections of the
% datasets.
[~,~,csvdata] = xlsread('VH_sections.csv');

% Select dataset, section and side. Check VH_sections.csv for the available
% default options.
dataset = 'male'; % 'male' or 'female'
section = 'legs'; % Check file 'VH_sections.csv' for available sections
side    = 'right';

% Set image dimensions
pixel_size = [0.33 0.33];  % will be rounded to the nearest multiple of 0.33
slice_thickness = 5; % will be rounded to the nearest multiple of 0.33/1 for female/male data

appendix = '5mm'; % append to filename

% Set compression flag. If true, the output will be compressed (.nii.gz)
compressed = true;

% If true, a binary mask with the foreground (non-zero values) will be
% created as well.
writemask = false;

%% Build up the default filename.
nifti_path = fullfile(VH_data_main,dataset,'nifti');
if exist(nifti_path,'dir')~=7;mkdir(nifti_path);end
if any(strcmp(section,{'legs','thighs','shoulders','feet','forearm'}))
    row_idx = find(strcmp(csvdata(:,1),dataset) & strcmp(csvdata(:,2),section) & strcmp(csvdata(:,3),side));
    nifti_filename = [dataset '_' section '_' side];
else
    row_idx = find(strcmp(csvdata(:,1),dataset) & strcmp(csvdata(:,2),section));
    nifti_filename = [dataset '_' section];
end

if ~isscalar(row_idx)
    error('Selected section not found in the csv file')
end

if ~isempty(appendix)
    nifti_filename = [nifti_filename '_' appendix];
end
nifti_filename = [nifti_filename '.nii'];

%%
% Create the NIfTI file.
data_path = fullfile(VH_data_main,dataset,'fullcolor','fullbody');
[fname_nii,fname_mask] = fullcolor2nii(dataset,...
    [pixel_size slice_thickness],...
    data_path,...
    csvdata{row_idx,4},...
    csvdata{row_idx,5},...
    csvdata{row_idx,6}:csvdata{row_idx,7},...
    csvdata{row_idx,8}:csvdata{row_idx,9},...
    fullfile(nifti_path,nifti_filename),...
    compressed,...
    writemask);

