function [data] = sanatize_zeros(data)
%SANATIZE_ZEROS Summary of this function goes here
%   Detailed explanation goes here
for colum = size(data,2):-2:1 % takes the whole data in the dimension 2 and reads in the opposite direction(hence the -) and skips 2(cuz skips the columns with zero and also the columns of its respective time value) and does this till the 1st column
    if all(data(:,colum)==0|isnan(data(:,colum))) %Here it is asking the function to remove the data if ALL the data in a particular column are 0 or NaN; How the OR function works is that : it will check a single cloumn for both 0 and nan. If it gets any one.. it will remove that column, if it does not get either(that is, both 0) then it will keep that column.
        data(:,(colum-1):colum)=[];
    end    
end
end

