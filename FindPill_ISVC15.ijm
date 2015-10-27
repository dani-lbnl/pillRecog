/*
 * Pill recognition for NIH database
 * dr = reference image: controlled background and images are 4,000 x 1,600
 * dc = consumer images: variable background, shades, and images are 4,416 x 3,312
 * Algorithm:
 * 1. hsv(downsampled)
 * 2. use v
 * 3. edge detection
 * 4. get statistics
 * 5. find connected regions with intensity > mu+sigma
 * 
 * Created by Dani Ushizima - dani.lbnl@gmail.com
 * Modified on 10/16/2015
 * obs: adapted to dr dataset only ; soon to include dc
 */
macro "FindPill"{

	machine = "/Users/dani/Dropbox/AQUI/BIDS/"; 
	outputPath = machine+"projects/NIH_PIL/pir-challenge/tests/edge_oct/";  //"/Users/ushizima/Dropbox/aqui/BIDS/projects/nih_pil/fiji/";	
	File.makeDirectory(outputPath);
	File.makeDirectory(outputPath+"feat");
	inputdir = machine+"projects/NIH_PIL/pir-challenge/dr/";
	FileList = getFileList(inputdir);

	//setBatchMode(true);
	setOption("BlackBackground", true);

	bFeatureExtraction = true;
	bVisualization = true;
	shrinkFactor = 0.2;
	
	bkgRoll = 40;//80;
	sigmaSpatial = 3;
	sigmaRange = 50;
	minSize = 10000* shrinkFactor; //30k??? if found less than the half of the area, then don't even measure the crap
	minCirc = 0.1;

	N=FileList.length;
	print("Wait... processed started..............");
	start = getTime;

	
	for (k=0;k<N;k++){
		run("Close All");
		print("Processing image "+FileList[k]); 
		open(inputdir+FileList[k]); 
		//test a single image with this 
		// open(inputdir+"00555-1055-86_PART_1_OF_1_CHAL10_SB_E33071D3.jpg");
		pillRecog(); //main function
	}
	print("Time of processing=" + d2s(getTime-start,2));
	print("----------------------------------");
}



/******************************************
 * Main function
 */
function pillRecog(){	
	filename = getTitle;
	rename("fullRes"); // this is used in the feature extraction
	run("TransformJ Scale", "x-factor="+shrinkFactor+" y-factor="+shrinkFactor+" z-factor="+shrinkFactor+" interpolation=linear"); //this destroys raw data
	rename("Orig");
	run("Properties...", "channels=1 slices=1 frames=1 unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1");
	selectWindow("fullRes"); close();

	//reduce canvas
	x=round(0.1*getWidth);
	y=round(0.2*getHeight);
	w=getWidth - 2*x;
	h=getHeight - 2*y;
	run("Canvas Size...", "width="+w+" height="+h+" position=Center");
	run("Duplicate...","title=OrigScaled duplicate");

	
	/**************  Segmentation **************/
	selectWindow("OrigScaled");
		run("Find Edges");//run("Multiband Sobel edges"); //change here depending on the Fiji version you are using!
		for (s=0;s<3;s++)
			run("Sharpen");
		run("Maximum...", "radius=2");
		run("8-bit");
		setThreshold(30,255);
		run("Convert to Mask");		
		run("Erode"); run("Erode"); 
		rename("Mask");
		//next 2 lines are overtesting in case there are spurious small objects --- can be eliminated for DR
		run("Set Measurements...", "area  center limit redirect=None decimal=4");
		run("Analyze Particles...", "size="+minSize+"-Infinity pixels circularity="+minCirc+"-1.00 show=Masks display exclude clear include in_situ");
		selectWindow("Orig"); 	
		run("Duplicate...","title=OrigGray duplicate");	  	
		run("8-bit");	
	
	
		
	/**************  Measurements **************/ 
	if(bFeatureExtraction){
		
		run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction limit redirect=OrigGray decimal=4");
		selectWindow("Mask"); //focus must be on the binary image and measurements set to graylevel image
		run("Analyze Particles...", "size="+minSize+"-Infinity pixels circularity="+minCirc+"-1.00 show=Masks display exclude clear include in_situ");//100=40microns
		saveAs("Results", outputPath+ "feat/" + substring( filename, 0, lengthOf(filename)-4 ) + ".xls");
		wait(2000);
	}
	
	/**************  Visualization **************/ 
	if(bVisualization){
		selectWindow("Mask");
		run("Find Edges");
		rename("Edges");
		run("Dilate"); //make the border more visible
		
		run("Red");
		imageCalculator("Add", "Orig","Edges");
		//selectWindow("OrigScaled");
		
		//run("Scale...", "x=0.25 y=0.25 width=600 height=400 interpolation=Bilinear average create title=[final]");
		//run("Resize ", "sizex=25.0 sizey=25.0 method=Least-Squares interpolation=Cubic unitpixelx=false unitpixely=false");
		//? do you want to resize here??
		//run("TransformJ Scale", "x-factor=0.25 y-factor=0.25 z-factor=0.25 interpolation=linear");
		saveAs("Jpeg", outputPath+filename); 
		//setBatchMode(false);
	}

}


