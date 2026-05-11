N = 5;		// nr of times to run the benchmark
radius = 4;	// 3D mean radius

width = 512;
height = 512;
depth = 50;

init_GPU();
run("Clear Results");
run("Close All");

benchmark_CPU();
benchmark_GPU();
benchmark_disk();


// ---- functions ----

function benchmark_CPU() {
	// CPU processing
	for(i=0 ; i<N ; i++) {
		// generate data
		timeStart = getTime();
		newImage("bigData", "8-bit noise", width, height, depth);
		duration = getTime() - timeStart;
		print("data generation (single core CPU) took: " + duration + " ms");
		setResult("Data generation", i, duration);
	
		// convolve data
		timeStart = getTime();
		run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 24 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n] normalize stack");
		duration = getTime() - timeStart;
		print("Convolution on all frames took: " + duration + " ms");
		setResult("Convolution (CPU)", i, duration);
	
		// 3D mean filter
		timeStart = getTime();
		run("Mean 3D...", "x=4 y=4 z=4");
		duration = getTime() - timeStart;
		print("4-pixel 3D mean filter on all frames (multi-core CPU) took: " + duration + " ms");
		setResult("3D mean (CPU)", i, duration);
	
		close();
	}
}
function benchmark_disk() {
	for(i=0 ; i<N ; i++) {
		newImage("Untitled", "16-bit black", 4096, 4096, 100);
		datasize = (2*4096*4096*100)/pow(2,20);  //MB
		timeStart = getTime();
		saveAs("Raw Data", "C:/Temp/temp_file");
		duration = getTime() - timeStart;
		setResult("Data saving MB/s", i, datasize/(duration/1000));
		close();
		timeStart = getTime();
		run("Raw...", "open=C:/Temp/temp_file image=[16-bit Unsigned] width=4096 height=4096 number=100");
		duration = getTime() - timeStart;
		setResult("Data loading MB/s", i, datasize/(duration/1000));
		close();
	}
}
function benchmark_GPU() {
	// GPU processing
	
	// generate kernel image
	newImage("kernel", "32-bit white", 5, 5, 1);
	changeValues(0, 65536, -1);
	setPixel(2,2,24);
	
	// generate data
	newImage("bigData", "8-bit noise", width, height, depth);
	bigData = "bigData";
	
	for(i=0 ; i<N ; i++) {
	
		// push data to GPU
		timeStart = getTime();
		Ext.CLIJ2_push(bigData);
		duration = getTime() - timeStart;
		print("Pushing data to the GPU took: " + duration + " ms");
		setResult("Push to GPU", i, duration);
	
		// convolve data
		timeStart = getTime();
		Ext.CLIJ2_convolve(bigData, "kernel", "bigData_convolved");
		duration = getTime() - timeStart;
		print("Convolution on all frames (GPU) took: " + duration + " ms");
		setResult("Convolution (GPU)", i, duration);
		Ext.CLIJ2_release("bigData_convolved");
	
		// 3D mean filter
		timeStart = getTime();
		Ext.CLIJ2_mean3DBox(bigData, bigData_mean, 4, 4, 4);
		duration = getTime() - timeStart;
		print("4-pixel 3D mean filter on all frames (GPU) took: " + duration + " ms");
		setResult("3D mean (GPU)", i, duration);
	
		// pull data to GPU
		timeStart = getTime();
		Ext.CLIJ2_pull(bigData_mean);
		duration = getTime() - timeStart;
		print("Pulling data to the GPU took: " + duration + " ms");
		setResult("Pull from GPU", i, duration);
		
		Ext.CLIJ2_clear();
		close();
	}
}

function init_GPU() {
	run("CLIJ2 Macro Extensions", "cl_device=");
	Ext.CLIJ2_listAvailableGPUs();
	availableGPUs = Table.getColumn("GPUName");
	activeGPU = availableGPUs[0];
	run("CLIJ2 Macro Extensions", "cl_device=" + activeGPU);
	if (availableGPUs.length > 2) print("Multiple GPUs found. Currently using " + activeGPU);
	Ext.CLIJ2_getGPUProperties(gpu, memory, opencl_version);
	print("GPU: " + gpu);
	print("Memory in GB: " + (memory / 1024 / 1024 / 1024) );
	print("OpenCL version: " + opencl_version);
	Ext.CLIJ2_clear();
}

