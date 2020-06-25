clear
% Information about downloading the images can be found here:
% https://www.nlm.nih.gov/databases/download/vhp.html

% This script expects the .raw images of the Visible Human to be accessible
% in the folder VH_data_main. The code expects *unzipped* .raw files in
% subfolders male/fullcolor/fullbody and female/fullcolor/fullbody.

filename.csv = 'VH_sections.csv'; % CSV file
VH_data_main = 'E:\VH_data';      % Main path

%% ----------------- SETTINGS -----------------------
% dataset: 'male' or 'female' Visible Human data
% section: anatomical section to make NIfTI file of. See VH_sections.csv 
%          for available sections, or add your own to the csv file.
% side   : 'left' or 'right' - only applicable to some sections
% voxel_size: xyz resolution of image in mm. 
%             x=right-left
%             y=posterior-anterior
%             z=superior-inferior)
%   Note on resolution: the original Visible Human data has a voxel size of
%   0.33x0.33x1 mm for the male dataset and 0.33x0.33x0.33 for the female
%   dataset. The actual voxelsize of the NIfTI image will be rounded to the
%   nearest multiple of 0.33 (i.e., no interpolation will be done). The 
%   z-resolution (voxel_size(3)) for the male dataset will be rouned to the
%   nearest integer (e.g. 0.8 becomes 1).
% appendix: string to append to the default filename. The default filename
%           is <dataset>_<section>_<side>.nii, e.g. male_legs_left.nii.
% writemask:  If true, a binary mask with non-zero voxels will be created.
% compressed: If true, the NIfTI files be compressed (.nii.gz)
% nifti_path: Folder to which NIfTI files be saved. This folder will be 
%             created if it doesn't exist yet.
% data_path : 

dataset    = 'male';
section    = 'head';
side       = '';
voxel_size = [1 1 1];
appendix   = '1x1x1'; 
writemask  = false;
compressed = true;
nifti_path = fullfile(VH_data_main,dataset,'nifti');

%% Load the CSV-file with the metadata for selected sections of the
% datasets.
[~,~,csvdata] = xlsread(filename.csv);

%% Build up the default filename.
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

%% Call fullcolor2nii to convert the selected raw fullcolor images to a 
% 3D NIfTI file.

[fname_nii,fname_mask] = fullcolor2nii(dataset,...
    voxel_size,...
    fullfile(VH_data_main,dataset,'fullcolor','fullbody'),...
    csvdata{row_idx,4},...
    csvdata{row_idx,5},...
    csvdata{row_idx,6}:csvdata{row_idx,7},...
    csvdata{row_idx,8}:csvdata{row_idx,9},...
    fullfile(nifti_path,nifti_filename),...
    compressed,...
    writemask);

