# OrientingGUI
Orienting GUI for OCT Volume Scans, as described in Frost et al, 2022
The program requires three steps to run: 
1) One must run the ThorLabs MATLAB function titled ExtractVolumeScan. This function takes a .OCT file and turns it into a MATLAB array, which is what is necessary for the rest of the programs.
2) Then, one runs plane_approx. This is the "three-point" program that determines your anatomical coordinate vectors in optical coordinates. The program asks you for a few things:
  
  a) The name of your now-extracted Volume file (that created by ExtractVolumeScan).
  
  b) The number of B-Scans you want separating where you pick points. This value will determine the accuracy and locality of your planar approximation, as described in the paper. We usually choose 10 -- with an x-pixel size of 1.95um, this is 19.5um distance between selected points.
  
  c) The pixel sizes. These are determined when you take your volume.
  
  d) Where you want to save your file.

Then, you just pick your points. See if the lines do a good job at approximating BM in the B-Scan.

The plane_approx output file contains a few useful values -- the pixel sizes, the selected points, etc. Most importantly, it provides the unit normal vector to the BM in optical coordinates.
That is, this is the transverse direction written in optical (x,y,z) coordinates! Often, this is the only object of interest. If you need to do more, 

  3) Run Volume_gui. This will let you determine the positions of measurements/positions to measure in both coordinate systems. It has many parameters, perhaps best explained in the paper.

A worked out example is provided in the paper.

# Possible problems
We assume the default ThorImage coordinate settings are used to save the volume. These settings determine which dimensions in the 3-D arrays correspond to x, y and z.
IF YOU HAVE CHANGED THIS, you should either change it back before saving or you can pretty easily sift through the plane_approx code to switch a few indeces around.
One can find these orders in the .oct files once extracted.
