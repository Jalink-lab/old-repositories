import ij.IJ
import net.imglib2.img.ImagePlusAdapter 
import groovy.time.*

def main(){
	//def String groovyPath = "D:/gitlab_reps/generalimagejmacros/Toolbox" //contains reusable groovy code
	def String groovyPath = "E:/GitLab_Reps/generalimagejmacros/Toolbox"
	GroovyShell shell = new GroovyShell()
	def tools = shell.parse(new File(groovyPath,'RH_histogram.groovy'))
	
	imp = IJ.openImage("http://imagej.nih.gov/ij/images/boats.gif");
	img = ImagePlusAdapter.wrap(imp) //convert to imglib2
	imp.show()
	factory = img.factory()
	int[] dimensions = [1,3]
	edges = factory.create(dimensions)
	randomA = edges.randomAccess()
	randomA.get().set(0)
	randomA.fwd(1)
	randomA.get().set(50)
	randomA.fwd(1)
	randomA.get().set(52)
	def timeStart = new Date(),
	println tools.histogram(img,255,0,255) // 255 bins, range from 0 to 255
    def timeStop = new Date()
    println TimeCategory.minus(timeStop, timeStart)
	//println tools.histogram(img,10) // 10 bins, range from min to max
	//println tools.histogram(img) // floor(sqrt(number of element)) bins, range from min to max
	//println tools.histogram(img,edges) //custom edges defined above
}
main()