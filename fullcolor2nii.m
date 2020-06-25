% This script converts the raw image files of the Visible Human to NIfTI files.
function varargout = fullcolor2nii(dataset,voxel_size,data_path,first_file,last_file,sel_dim1,sel_dim2,nifti_filename,compressed,writemask)

% Set some default options.
if nargin < 10
    writemask = false;
    if nargin < 9
        compressed = true;
    end
end
% Make a list of all selected files.
files = dir(fullfile(data_path,'*.raw'));

% Get the index of the first and last file in the stack.
C = struct2cell(files);
F = fieldnames(files);
filenames = C(strcmp(F,'name'),:);
first_file_idx = find(strcmp(filenames,[first_file '.raw']));
last_file_idx  = find(strcmp(filenames,[last_file '.raw']));

% Raw image size. This should never be changed because all raw images have
% this dimension.
raw_size  = [2048,1216];

%% Make list of files to include in NIfTI image
voxel_size1     = voxel_size;

switch dataset
    case 'male'
        % Get the actual slice thickness: multiples of 1.
        slice_gap = round(voxel_size1(3) / 1);
        if slice_gap ==0;slice_gap = 1;end
        voxel_size(3) =  slice_gap;
        
        % Get z-coordinate of the origin of the image coordinate system.
        Oz = -(first_file_idx-1)*1;
        
        % Set origin pixel.
        pixel_offset = [1017 581];
    case 'female'
        % Get the actual slice thickness: multiples of 0.33.
        slice_gap = round(voxel_size1(3) / 0.33);
        if slice_gap ==0;slice_gap = 1;end
        voxel_size(3) =  slice_gap * 0.33;
        
        % Get z-coordinate of the origin of the coordinate system
        Oz = -(first_file_idx-1)*0.33;
        
        % Set origin pixel.
        pixel_offset = [1046 544];
end

% Calculate the actual voxel size (multiples of 0.33).
pixel_gap       = round(voxel_size1(1:2) ./ 0.33);
voxel_size(1:2) = pixel_gap * 0.33;

% Print the requested and actual voxel size to the command window.
fprintf('\n--------------------------------------------------\n')
fprintf('Requested / actual voxel size = [%.2f,%.2f,%.2f] / [%.2f,%.2f,%.2f] mm',...
    voxel_size1(1),voxel_size1(2),voxel_size1(3),...
    voxel_size(1),voxel_size(2),voxel_size(3));
fprintf('\n--------------------------------------------------\n')
files = files(first_file_idx:slice_gap:last_file_idx);

% Image size after cropping.
crop_size = [length(sel_dim1(1):pixel_gap(1):sel_dim1(end))...
             length(sel_dim2(1):pixel_gap(2):sel_dim2(end))];

% Create an empty image with the correct dimensions.
IMG = uint8(zeros(crop_size(1),crop_size(2),length(files),1,3));
if writemask==true
    MASK = uint8(zeros(crop_size(1),crop_size(2),length(files)));
end
for slice_nr = 1 : length(files)
    fprintf('Reading %d of %d\n',slice_nr,length(files))
    
    % Read the raw image
    image_filename = fullfile(data_path,files(slice_nr).name);
    mask_filename  = fullfile(data_path,'masks',strrep(files(slice_nr).name,'.raw','.mat'));
    fid=fopen(image_filename,'r');
    I=fread(fid,prod(raw_size)*3,'*uint8');
    fclose(fid);
    
    % If all values are zero the image does not contain image data.
    % Continue with the next.
    if all(I==0);continue;end
    
    % Reshape into original image dimensions.
    I = reshape(I,raw_size(1),raw_size(2),3);
    
    % Cropped image at full in-plane resolution
    I_cropped = I(...
        sel_dim1,...
        sel_dim2,...
        1:3);
    
    % Create binary mask of the foreground (background=0)
    slice_mask = load(mask_filename);
    slice_mask = slice_mask.mask(sel_dim1,sel_dim2);
    
    % Final slice at requested in-plane resolution
    IMG(:,:,slice_nr,1,1:3) = ...
        I_cropped(1:pixel_gap(1):end,1:pixel_gap(2):end,1:3) .* ...
        repmat(uint8(slice_mask(1:pixel_gap(1):end,1:pixel_gap(2):end)),1,1,3);
    if writemask == true
        MASK(:,:,slice_nr) = ...
            uint8(slice_mask(1:pixel_gap(1):end,1:pixel_gap(2):end));
    end
% %       Uncomment for diagnostic purposes only.
%         figure;
%         image(I_cropped) %;colormap gray
%         hold on
%         rgb = repmat(slice_mask,1,1,3);rgb(:,:,[1 3]) = 0;
%     %     set(h2,'CData',rgb,'AlphaData',single(slice_mask*0.8))
%         h2 = image(rgb,'AlphaData',slice_mask*0.8);
%         axis equal
end

%% Write NIfTI RGB-file

% Load variable 'info' with the template NIfTI header information
load('nifti_info_uint8.mat')
% Get x- and y-coordinate of the image coordinate system.
Ox = (sel_dim1(1)-pixel_offset(1))*0.33;
Oy = (sel_dim2(1)-pixel_offset(2))*0.33;

% Overwrite the image size and pixel dimensions
flipsgn = [-1 1 -1]; % flip x and z axis for correct anatomical orientation of the NIfTI file

info.ImageSize = size(IMG);
info.PixelDimensions = [voxel_size 0 0];
T = diag([info.PixelDimensions(1:3).* flipsgn 1]);
T(4,1:3) = [-Ox Oy Oz];
info.Transform.T = T;
info.raw.srow_x = T(:,1)';
info.raw.srow_y = T(:,2)';
info.raw.srow_z = T(:,3)';
niftiwrite(IMG,nifti_filename,info,...
    'Compressed',compressed,...
    'Version','NIfTI1')
if compressed == true
    fprintf('Image saved as %s.gz\n',nifti_filename)
else    
    fprintf('Image saved as %s\n',nifti_filename)
end

%% Write NIfTI mask
if writemask == true
    % Load variable 'info' with the template NIfTI header information
    load('nifti_info_uint8.mat')
    mask_filename = strrep(nifti_filename,'.nii','_mask.nii');
    
    % Overwrite the image size and pixel dimensions
    info.ImageSize = size(MASK);
    info.PixelDimensions = voxel_size;
    info.Transform.T = T;
    info.raw.srow_x = T(:,1)';
    info.raw.srow_y = T(:,2)';
    info.raw.srow_z = T(:,3)';
    niftiwrite(MASK,mask_filename,info,...
        'Compressed',compressed,...
        'Version','NIfTI1')
    if compressed == true
        fprintf('Mask saved as %s.gz\n',mask_filename)
    else    
        fprintf('Mask saved as %s\n',mask_filename)
    end
end

%% Output the filenames.
if nargout > 0
    varargout{1} = nifti_filename;
    if nargout > 1
        if writemask == true
            varargout{2} = mask_filename;
        else
            varargout{2} = [];
        end
    end
end
end