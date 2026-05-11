"""
Segment cells using cellpose
"""
import numpy as np
from cellpose import models  # https://dist.mxnet.io/python has mxnet-cu100mkl
from tifffile import TiffFile
from tifffile import imwrite


def segment_cells(tiffilesin, tiffilesout, channels, gpu=True):
    """
    The data is saved as a multi image .tiff file with x-y-t as the layout.
>>>>>>>>>>>> is this really true? they are two-channel 'single image' tifs<<<<<<<<<<<Ask Rolf
    :param tiffilesout:
    :param tiffilesin:
    :param channels:
    :param gpu: use GPU for segmentation
    :return: mask
    """
    imgs = []
    meta_data = []
    new_tiffilesout = []
    # read all .tif files, check if outputfile already exists, if not, add to list.
    for ct, file in enumerate(tiffilesin):
        if tiffilesout[ct].exists():
            continue
        tif_file = TiffFile(file)
        img = tif_file.asarray()
        md = tif_file.shaped_metadata[0]
        md.pop('shape')  # somehow it wants to include shape...
        meta_data.append(md)
        imgs.append(img)
        new_tiffilesout.append(tiffilesout[ct])
    # run automatic segmentation
    model = models.Cellpose(gpu=gpu, model_type='cyto')
    labelmaps, flows, styles, diams = model.eval(imgs, diameter=20, channels=channels,
                                                 cellprob_threshold=0.5, do_3D=False)
    for i, new_file in enumerate(new_tiffilesout):
        imwrite(new_file, labelmaps[i].astype(np.uint16), metadata=meta_data[i])
