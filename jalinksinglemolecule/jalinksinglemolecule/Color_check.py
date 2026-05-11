"""
Match .csv files together
"""

from pathlib import Path

# pth = Path('G:\\', 'SurfDrive', 'Rolf_and_Leila', 'CSV-Archive', '2020', '01', '28 (Leila-H3K9me3WT)', 'Results-v2.41')
pth = Path('/Users', 'l.nahidiazar', 'Desktop', 'folder')
print("Will now go over all .csv files in " + pth.name)

def color_check(pth):

    A647_collection = []
    A532_collection = []
    A488_collection = []
    roifile_collection = []

    for x in pth.iterdir():
        if x.is_file() & (x.suffix == '.csv'):
            if x.name.endswith("647.csv"):
                A647_collection.append(x)
            elif x.name.endswith("532_chromcorr.csv"):
                A532_collection.append(x)
            elif x.name.endswith("488_chromcorr.csv"):
                A488_collection.append(x)
            if x.is_file() & (x.suffix == '.roi'):
                roifile_collection.append(x)

    A647_collection.sort()
    A532_collection.sort()
    A488_collection.sort()

    # Here I check if every image has all the corresponding colors.
    cell_list = []  # list with all the individual cell-dictionaries
    for A647_file in A647_collection:
        # make a cell dictionary with the files that belong to one cell
        cell = {'histone_csvfile': A647_file,
                'lad_csvfile': None,
                'lamin_csvfile': None,
                'lamin_roifile': None}

        file_no = A647_file.name[:5]  # need to match this
        print("matching " + file_no)
        for A532_file in A532_collection:
            if file_no in A532_file.name:
                cell['lamin_csvfile'] = A532_file
        for A488_file in A488_collection:
            if file_no in A488_file.name:
                cell['lad_csvfile'] = A488_file
        for roi_file in roifile_collection:
            if file_no in roi_file.name:
                cell['lamin_roifile'] = roi_file

        cell_list.append(cell)

    print(cell_list[0])
    
color_check(pth)
