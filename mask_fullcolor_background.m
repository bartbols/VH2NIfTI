function mask =  mask_fullcolor_background(img,threshold,minVoxels)
%MASK_FULLCOLOR_BACKGROUND 
% Returns a background mask created using a combination of erosion, 
% dilation and connected component analysis.

% 
if ndims(img) == 2
    el = ones(3,3);
elseif ndims(img) == 3
    el = ones(3,3,3);
else
    error('Only 2D or 3D images are accepted')
end


% % Erode a number of times
nErode = 3;
mask = img > threshold;
for i = 1 : nErode
    mask = imerode(mask,el);
end

% Keep only the n largest connected components
CC = bwconncomp(mask);
[len,CC_idx] = sort(cellfun(@length,CC.PixelIdxList),'descend');

mask = zeros(size(mask));
% if length(CC.PixelIdxList) < n
%     n = length(CC.PixelIdxList);
% end
n = find(len>minVoxels,1,'last');
for i = 1 : n
    mask(CC.PixelIdxList{CC_idx(i)}) = 1;
end
% 
% Dilate again
for i = 1 : nErode
    mask = imdilate(mask,el);
end

for slice_nr = 1 : size(mask,3)
    mask(:,:,slice_nr) = imfill(mask(:,:,slice_nr),'holes');
end

end

