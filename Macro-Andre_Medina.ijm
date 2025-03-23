var Results_folder = "Processed Images and Results"; //
run("Set Measurements...", "area mean standard min median redirect=None decimal=3");

dir = getDirectory("Choose a Directory");
if (!File.exists(dir + File.separator + Results_folder)) File.makeDirectory(dir + File.separator + Results_folder);
list_files = getFileList(dir);

for (a = 0; a < list_files.length; a++) {
path = dir+list_files[a];
if (endsWith(path, ".tif")) {
	
	print(path);
	
	//open image
	image_title = File.getNameWithoutExtension(path);
	print(image_title);
	run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");	
	run("Duplicate...", "title=[Seg_"+image_title+"]");
	
	//remove noise
	run("Fire");
	run("Gaussian Blur...", "sigma=1.5");
	run("Subtract Background...", "rolling=25");
	
	//Threshold image according to user input
	setAutoThreshold("Default dark");
	run("Threshold...");
	waitForUser("Waiting for Threshold", "Define the minimum threshold value and click 'OK'");
	close("Threshold*");
	
	//Segment signal according to size and circularity
	run("Analyze Particles...", "size=45-Infinity circularity=0.40-1.00 exclude include summarize add");
	selectWindow("Seg_"+image_title);
	run("Brightness/Contrast...");
	resetMinAndMax();
	waitForUser("", "Check if the cells are well segmented");
	
	//Ask user if the cells segmented are good or if it wants to add and/or remove cells manually  
	message = "If the cells segmented are okay press \"Continue\", if not press \"Add/remove cells manually?\"";
	yesLabel = "Continue";
	noLabel = "Add/remove cells manually";
	
	Option = getBoolean(message, yesLabel, noLabel);

	if (Option == 1) {
		//save image for segmentation and close
		selectWindow("Seg_"+image_title);
		saveAs(".tif", dir + File.separator + Results_folder + File.separator + "Seg_"+image_title);
		close("Seg_*");
		
		//select the original image in which the measuraments will be performed
		selectWindow(image_title+".tif");
		roiManager("deselect");
		roiManager("measure");
		
		//save measurements and ROIs with the name of the respective image
		saveAs("Results", dir + File.separator + Results_folder + File.separator + "Results_" + image_title + ".xls");
		roiManager("save", dir + File.separator + Results_folder + File.separator + "ROI_" + image_title + ".zip");
		
		//Close everything
		run("Clear Results");
		roiManager("delete");
		close("*");
		run("Close All");
	}
	else if (Option == 0) {
		//save image for segmentation
		selectWindow("Seg_"+image_title);
		saveAs(".tif", dir + File.separator + Results_folder + File.separator + "Seg_"+image_title);
		
		//show sugestions on how to add/remove cells
		setTool("freehand");;
		msg = " - To add cells, draw a ROI around the missing cell and press \"t\" to add to ROI Manager."
				+"\n "
				+"\n - To delete unwanted cells, click on them in the image and press \"Delete\" in ROI Manager"
				+"\n "
				+"\n Repeat as many times as necessary and press \"OK\" once you are ready to proceed";			
		
		//loop confirmation to make sure all changes to images were done before proceeding
		do {
			waitForUser("Suggestions", msg);
			check = getBoolean("Are you sure you are done with this image? If not, click \"No\" to continue correcting the segmentation");
		} while (check == 0);
		
		//Close the segmentation image
		close("Seg_*");
		
		//select the original image in which the measuraments will be performed
		selectWindow(image_title+".tif");
		roiManager("deselect");
		roiManager("measure");
		
		//save measurements and ROIs with the name of the respective image
		saveAs("Results", dir + File.separator + Results_folder + File.separator + "Results_" + image_title + ".xls");
		roiManager("save", dir + File.separator + Results_folder + File.separator + "ROI_" + image_title + ".zip");
		
		//Close everything
		run("Clear Results");
		roiManager("delete");
		close("*");
		run("Close All");
		}			
	}
}