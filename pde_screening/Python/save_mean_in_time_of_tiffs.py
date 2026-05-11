"""
15-june-2020
Automatically segment all cells and save the segmentation in the same folder.

 *  06-02-2020 (knockdown of PDE 3A and PDE 10 half with caged and half with IsoP/Prop/Forsk)
 *  07-01-2020 (extra IBMX and only cells with IsoP Prop and Forsk)
 *  05-12-2019 (caged cAMP)
 *  07-11-2019 (Chemical)
 *  02-05-2019 (Sravasti, with SiR-DNA, chemical)
 * Not on data from:
 *  05-04-2019 (Sravasti, chemical, manual ROI, good screen)
 *  26-04-2019 (Sravasti, infected)
"""
from tifffile import TiffFile
from tifffile import imwrite
import numpy as np
from pathlib import Path

paths = [Path('E:\\', '2019', '12', '05', 'segmented'),
         Path('E:\\', '2019', '11', '07', 'segmented'),
         Path('E:\\', '2020', '01', '07', 'segmented'),
         Path('E:\\', '2020', '02', '06', 'chemical', 'Segmented'),
         Path('E:\\', '2020', '02', '06', 'caged', 'Segmented')
         ]

cell_images = []
meta_data = []
for path in paths:
    for file in path.iterdir():
        if file.suffix == '.tif':
            if file.name[:-8] == '_sum.tif':
                continue
            tif_file = TiffFile(file)
            new_file = Path(file.parent, file.name[:-4] + "_sum.tif")
            metadata = tif_file.imagej_metadata
            clean_metadata = {}
            if metadata is not None:
                for key in metadata:
                    if type(metadata[key]) in {str, int, bool, float}:
                        clean_metadata[key] = metadata[key]
            img = tif_file.asarray()
            img = np.mean(img, axis=0)  # the images are static, we average over all frames
            imwrite(new_file, img.astype(np.float32), metadata=clean_metadata)
