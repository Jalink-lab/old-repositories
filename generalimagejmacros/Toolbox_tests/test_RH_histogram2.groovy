import ij.IJ
import groovy.time.*

def main(){
	//def String groovyPath = "D:/gitlab_reps/generalimagejmacros/Toolbox" //contains reusable groovy code
	def String groovyPath = "E:/GitLab_Reps/generalimagejmacros/Toolbox"
	GroovyShell shell = new GroovyShell()
	def tools = shell.parse(new File(groovyPath,'RH_histogram2.groovy'))
	//imp = IJ.openImage("http://imagej.nih.gov/ij/images/boats.gif")
	//imp.show()
	if (ij.WindowManager.getImageCount()==0){IJ.noImage();return;} 
	imp = ij.WindowManager.getCurrentImage()
	ip = imp.getProcessor()
	N = ip.width*ip.height
	double[] data = new double[N]
	int[] dataI = new int[N]
	for (int i=0;i<N;i++){
		data[i]=ip.get(i)
		dataI[i]=ip.get(i)
	}
	def timeStart = new Date()
	res  = tools.histogram(data, 2, 0, 255)
    def timeStop = new Date()
    println TimeCategory.minus(timeStop, timeStart)
	println res
    //fast method for integer values
    timeStart = new Date()
    res = tools.cumSumIdx(dataI,255)
    timeStop = new Date()
    println TimeCategory.minus(timeStop, timeStart)
	println res
}
main()