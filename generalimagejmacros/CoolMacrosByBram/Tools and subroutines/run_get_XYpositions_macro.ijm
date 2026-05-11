xml_file_path = "C:\\Users\\b.vd.broek\\surfdrive\\FALCON Analysis\\07-19-2018\\07-19-2018_baseline.ome-xml.txt";
//dir = File.getParent(xml_file_path);
dir = "C:\\Users\\b.vd.broek\\surfdrive\\SP8 cell positions";
macro_path = "C:\\Users\\b.vd.broek\\surfdrive\\BB_Macros_sufrdrive\\Tools and subroutines\\get_X_andY_positions_from_OME-XML_file2.ijm";

run("Set Measurements...", "area mean standard min centroid integrated stack redirect=None decimal=9");
getDimensions(width, height, channels, slices, frames);
getPixelSize(unit, pixelWidth, pixelHeight);
width = width*pixelWidth*1E-6;		//convert to meters
height = height*pixelHeight*1E-6;
print(width);

Tiles_string = runMacro(macro_path, xml_file_path);
Tiles = split(Tiles_string, "|");	//split string into an array of X,Y Tiles

Tile_pos_X = newArray(Tiles.length);
Tile_pos_Y = newArray(Tiles.length);
for(i=0;i<Tiles.length;i++) {
	Tile_coords=split(Tiles[i],",");	//Split into separate X and Y Tiles
	Tile_pos_X[i] = parseFloat(Tile_coords[0]);	//positions in meters
	Tile_pos_Y[i] = parseFloat(Tile_coords[1]);
}
print(Tile_pos_X.length+" tiles found.");
Plot.create("Positions", "X (m)", "Y (m)");
Plot.setFrameSize(800, 800);
Plot.setLineWidth(1);
Plot.setColor("white");
Plot.add("crosses", Tile_pos_X, Tile_pos_Y);

//Calculate the absolute positions of the selected cells

//Draw tiles as squares
lefts = AddScalarToArray(Tile_pos_X, -width/2);
tops = AddScalarToArray(Tile_pos_Y, -height/2);
rights = AddScalarToArray(Tile_pos_X, width/2);
bottoms = AddScalarToArray(Tile_pos_Y, height/2);
Plot.setColor("lightgray");
Plot.drawShapes("rectangles", lefts, tops, rights, bottoms);

Cell_pos_X = newArray(roiManager("count"));
Cell_pos_Y = newArray(roiManager("count"));
for(i=0;i<roiManager("count");i++) {
	roiManager("select",i);
	List.setMeasurements();
	X = List.getValue("X")*1E-6;
	Y = List.getValue("Y")*1E-6;
	Tile = List.getValue("Slice")-1;
	Cell_pos_X[i] = Tile_pos_X[Tile] - width/2 + X;
	Cell_pos_Y[i] = Tile_pos_Y[Tile] + height/2 - Y;
}
Plot.setLineWidth(2);
Plot.setColor("red");
Plot.add("dots", Cell_pos_X, Cell_pos_Y);
Plot.setFormatFlags("11001100001111");	//Do not draw the grid
Plot.setAxisLabelSize(18, "options");
Plot.show();
//Generate RGN file, to be loaded in the LasX Navigator

preamble = "\<StageOverviewRegions\>\n\<Regions\>\n\<ShapeList\>\n\<Items\>\n"
postamble = "\</Items\>\n\<FillMaskMode\>None\</FillMaskMode\>\n\<VertexUnitMode\>Pixels\</VertexUnitMode\>\n\</ShapeList\>\n\</Regions\>\n\</StageOverviewRegions\>\n";

print("\\Clear");
print(preamble);
for(i=0;i<roiManager("count");i++) {
	start = "\<Item"+i+"\>\n\<Number\>"+i+1+"\</Number\>\n\<Name/\>\n\<Tag\>1Image\</Tag\>\n\<Identifier\>3fce88a0-cffb-41cd-c9ba-13cdc450ca5a\</Identifier\>\n\<Group\>-1\</Group\>\n\<Type\>Point\</Type\>\n\<Visible\>true\</Visible\>\n\<LineThickness\>2\</LineThickness\>\n\<EndBarLength\>20\</EndBarLength\>\n\<Stroke\>R:255,G:255,B:255,A:255\</Stroke\>\n\<Fill\>R:1,G:0,B:0,A:0\</Fill\>\n\<FillMaskMode\>Add\</FillMaskMode\>\n\<Font\>\n\<Family\>Arial\</Family\>\n\<Size\>14\</Size\>\n\<Bold\>false\</Bold\>\n\<Italic\>false\</Italic\>\n\<Strikeout\>false\</Strikeout\>\n\<Underline\>false\</Underline\>\n\</Font\>\n\<LabelText/\>\n\<LabelTextColor\>R:0,G:0,B:0,A:255\</LabelTextColor\>\n\<LabelBackgroundColor\>R:255,G:255,B:176,A:255\</LabelBackgroundColor\>\n\<LabelOffsetX\>0\</LabelOffsetX\>\n\<LabelOffsetY\>0\</LabelOffsetY\>\n\<Angle\>0\</Angle\>\n\<Verticies\>\n\<Items\>\n\<Item0\>\n";
	middle = "\<X\>"+d2s(Cell_pos_X[i],10)+"\</X\>\n\<Y\>"+d2s(-Cell_pos_Y[i],10)+"\</Y\>\n";
	end = "\<Z\>0\</Z\>\n<T>0</T>\n</Item0>\n</Items>\n</Verticies>\n<DecoratorColors>\n<Items />\n</DecoratorColors>\n<ExtendedProperties>\n<Items />\n</ExtendedProperties>\n<TileColor>R:192 ,G: 192,B: 192,A: 64</TileColor>\n<Palette />\n</Item"+i+">\n";
	print(start+middle+end);
}
print(postamble);

selectWindow("Log");
saveAs("text",dir+File.separator+"selected_positions.txt");
if(File.exists(dir+File.separator+"selected_positions.rgn")) File.delete(dir+File.separator+"selected_positions.rgn");
File.rename(dir+File.separator+"selected_positions.txt",dir+File.separator+"selected_positions.rgn");



//Multiplies all elements of an array with a scalar
function AddScalarToArray(array, scalar) {
	updated_array=newArray(lengthOf(array));
	for (a=0; a<lengthOf(array); a++) {
		updated_array[a]=array[a]+scalar;
	}
	return updated_array;
}
