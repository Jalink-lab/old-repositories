import ij.IJ
import net.imglib2.img.ImagePlusAdapter 
import ij.process.ImageProcessor

def main(){
	def String groovyPath = "F:/Git Repositories/generalimagejmacros/Toolbox" //contains reusable groovy code
	GroovyShell shell = new GroovyShell()
	def tools = shell.parse(new File(groovyPath,'BBhistogram.groovy'))

	float[] data = [1,1,1,1,2,2,2,2,3,3,3,3,100]
	println tools.BBhistogram(data,3,0,5)

}
main()
