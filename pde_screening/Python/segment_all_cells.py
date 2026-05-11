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
from cellpose import models
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
        if file.suffix == '.tif' and file.name.endswith('_sum.tif'):
            tif_file = TiffFile(file)
            frameinterval = tif_file.shaped_metadata[0].get('finterval', -1)
            if frameinterval == -1:
                print('WARNING: did not find frame interval in file ' + str(file))
            img = tif_file.asarray()
            meta_data.append((file, frameinterval))
            cell_images.append(img)

model = models.Cellpose(gpu=True, model_type='cyto')
labelmaps, flows, styles, diams = model.eval(cell_images, diameter=20, channels=[1, 2], cellprob_threshold=0.5)
