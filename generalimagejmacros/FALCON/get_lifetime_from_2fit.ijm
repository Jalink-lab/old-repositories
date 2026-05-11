// Calculate lifetime and intensity from fitted 2-component FALCON data.
// Input: a 2-channel image with components

#@ Double(label="Lifetime component 1(ns)",value=0.6) tau1
#@ Double(label="Lifetime component 2(ns)",value=3.4) tau2
#@ Double(label="Min. displayed lifetime(ns)",value=2) min
#@ Double(label="Max. displayed lifetime(ns)",value=3) max

setBatchMode(true);
original = getTitle();
//Get rid of the extension in the name (if any)
name = substring(original, 0, lastIndexOf(original, "."));
run("Duplicate...", "title=IntensityStack duplicate");
run("32-bit");
run("Split Channels");
imageCalculator("Add create 32-bit stack", "C1-IntensityStack","C2-IntensityStack");
rename("SumIntensity");
run("Enhance Contrast", "saturated=0.35");
selectWindow("C1-IntensityStack");
run("Multiply...", "value="+tau1+" stack");
selectWindow("C2-IntensityStack");
run("Multiply...", "value="+tau2+" stack");
imageCalculator("Add create 32-bit stack", "C1-IntensityStack","C2-IntensityStack");
rename("SumIntensity2")
imageCalculator("Divide create 32-bit stack", "SumIntensity2","SumIntensity");
rename(name+"_weighted_lifetime");
close("C1-IntensityStack");
close("C2-IntensityStack");
close("SumIntensity2");

//rename and apply display settings
selectWindow("SumIntensity");
rename(name+"_intensity");

selectWindow(name+"_weighted_lifetime");
run("Physics black");
setMinAndMax(min, max);
setBatchMode("exit and display");
