# VH2NIfTI

This GitHub repository contains code to convert raw Visible Human images to
NIfTI files that can be used in most image processing software.

---------- GETTING THE RAW DATA ----------
Step 1: Get the data.

The Visible Human data is freely available. 
Information about downloading the raw data can be found here:
https://www.nlm.nih.gov/databases/download/vhp.html

The code expects unzipped .raw files to be in a folder with the following
structure:
<main_path>/male/fullcolor/fullbody
<main_path>/female/fullcolor/fullbody

Make sure to unzip the raw images (e.g. using 7-zip) before using this code.

Step 2: Get the masks
Download the masks from GitHub (folders male/masks.zip and female/masks.zip), 
unzip the files and place the folder 'masks' in the folders fullcolor/fullbody 
of the corresponding dataset.

----- CREATE NIFTI FILES -----
Run make_nifti.m to create NIfTI files of selected parts of the anatomy.
This script expects Matlab's Image Processing Toolbox to be installed. 
The code has been developed and tested in Matlab 2019b.

---------- VIEWING THE DATA ----------
To view the data in ITK-SNAP
- load an image (File > Open Main Image...>
- go to Tools > Layer Inspector
- in the tab General set the Display mode to 'RGB Display'.

(Note that some slices are missing because these slices were missing in the original dataset as well.)