"""
Open all .tiff files and save the mean of the data in time
"""
from pathlib import Path
import numpy as np
from tifffile import TiffFile
from tifffile import imwrite


def save_mean_in_time_of_tiffs(inpath, outpath):
    """
    Open all .tiff files and save the mean of the data in time
    :param outpath: will output mean .tif files
    :param inpath: will search the path for .tif files
    Note: the inpath contains multi-tifs with intensity, the outpath contains
    a single-image tifs with _mean added to the filename
    """
    outpath.mkdir(parents=True, exist_ok=True)  # create path and all parent dirs, ignore warning for already existing
    for file in inpath.iterdir():
        if file.suffix == '.tif':
            if file.name[:-8] == '_mean.tif': #just in case someone already. I think this is fundamenttaly wrong
            
                continue
            tif_file = TiffFile(file)
            new_file = Path(outpath, file.name[:-4] + "_mean.tif")
            if new_file.exists():
                continue
            metadata = tif_file.imagej_metadata
            clean_metadata = {}
            if metadata is not None:
                for key in metadata:
                    if type(metadata[key]) in {str, int, bool, float}:
                        clean_metadata[key] = metadata[key]
            img = tif_file.asarray()
            img = np.mean(img, axis=0)  # the images are static, we average over all frames
            imwrite(new_file, img.astype(np.float32), metadata=clean_metadata)
