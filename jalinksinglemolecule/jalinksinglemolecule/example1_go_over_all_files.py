"""
Shows how to go over all files in a folder and its subfolders
"""
from pathlib import Path  # This is the modern way of handeling paths (since python 3.4) thanks Leila!
pth = Path('G:\\', 'SurfDrive', 'Rolf_and_Leila', 'CSV-Archive', '2020', '01', '28 (Leila-H3K9me3WT)', 'Results-v2.41')
print("Will now go over all files and folders in "+pth.name)
for x in pth.iterdir():
    print(x)

print("Will now go over all files in "+pth.name)
for x in pth.iterdir():
    if x.is_file():
        print('found file: ' + x.name)
        print('it extension is: ' + x.suffix)

print("Will now go over all .csv files in "+pth.name)
for x in pth.iterdir():
    if x.suffix == '.csv':
        print('found file: ' + x.name)

# very concise way of making a list with all .csv files in the folder:
my_csv_files = [x for x in pth.iterdir() if x.suffix == '.csv']
