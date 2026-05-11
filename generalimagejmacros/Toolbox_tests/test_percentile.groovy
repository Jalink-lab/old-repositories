import ij.IJ
import net.imglib2.img.ImagePlusAdapter 

def main(){
	def String groovyPath = "E:/GitLab_Reps/generalimagejmacros/Toolbox" //contains reusable groovy code
	GroovyShell shell = new GroovyShell()
	def tools = shell.parse(new File(groovyPath,'percentile.groovy'))
	
	imp = IJ.openImage("http://imagej.nih.gov/ij/images/boats.gif");
	img = ImagePlusAdapter.wrap(imp) //convert to imglib2
	println tools.percentile(img, 0.4)
	ip = imp.getProcessor()
	ip.setThreshold(tools.percentile(img,0.2),tools.percentile(img,0.8),ip.OVER_UNDER_LUT)
	imp.show()
}
main()