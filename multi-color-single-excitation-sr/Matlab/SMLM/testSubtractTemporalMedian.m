%mex subtractTemporalMedian.cpp;
fileName = 'testfile.tif';
tiffInfo = imfinfo(fileName);   
testTiff = zeros(tiffInfo(1).Height,tiffInfo(1).Width,numel(tiffInfo),'uint16');      %# Preallocate the cell array
for fr = 1:numel(tiffInfo)
  testTiff(:,:,fr) = uint16(imread(fileName,'Index',fr,'Info',tiffInfo));
end

fileName = 'resultfile.tif';
tiffInfo = imfinfo(fileName);  
resultTiff = zeros(tiffInfo(1).Height,tiffInfo(1).Width,numel(tiffInfo),'uint16');      %# Preallocate the cell array
for fr = 1:numel(tiffInfo)
  resultTiff(:,:,fr) = uint16(imread(fileName,'Index',fr,'Info',tiffInfo));
end

window = 101;
offset = 100;
tic
unrankArray = denseRank(testTiff);
unrankArray = unrankArray(1:find(unrankArray>0,1,'last'));
subtractTemporalMedian(testTiff,unrankArray,window,offset);
toc
all(testTiff(:)==resultTiff(:))