function [position] = import_position_results(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as column vectors.
%   [position] = import_position_results(FILENAME) Reads data from text file FILENAME for the
%   default selection.
%
%   [position] = import_position_results(FILENAME, STARTROW, ENDROW) Reads data from rows STARTROW
%   through ENDROW of text file FILENAME.
%
% Example:
%   [position] = import_position_results('test_RadGyro_Volo11_COM19OLOOresthres_position.txt',2, 7919);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2017/01/13 09:34:10

%--- * --. --- --. .--. ... * ---------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __|
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 1.0 beta 5 Merry Christmas
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2019 Mirko Reguzzoni, Eugenio Realini
%  Written by:
%  Contributors:     ...
%  A list of all the historical goGPS contributors is in CREDITS.nfo
%--------------------------------------------------------------------------
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------
% 01100111 01101111 01000111 01010000 01010011
%--------------------------------------------------------------------------

%% Initialize variables.
if nargin<=2
    startRow = 2;
    endRow = inf;
end

%% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%24s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%17s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', '', 'WhiteSpace', '', 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Remove white space around all cell columns.
dataArray{13} = strtrim(dataArray{13});

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[2,3,4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20,21,22]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;

            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

% Convert the contents of columns with dates to MATLAB datetimes using date
% format string.
try
    dates{1} = datetime(dataArray{1}, 'Format', 'yy/MM/dd HH:mm:ss.SSS', 'InputFormat', 'yy/MM/dd HH:mm:ss.SSS');
catch
    try
        % Handle dates surrounded by quotes
        dataArray{1} = cellfun(@(x) x(2:end-1), dataArray{1}, 'UniformOutput', false);
        dates{1} = datetime(dataArray{1}, 'Format', 'yy/MM/dd HH:mm:ss.SSS', 'InputFormat', 'yy/MM/dd HH:mm:ss.SSS');
    catch
        dates{1} = repmat(datetime([NaN NaN NaN]), size(dataArray{1}));
    end
end

anyBlankDates = cellfun(@isempty, dataArray{1});
anyInvalidDates = isnan(dates{1}.Hour) - anyBlankDates;
dates = dates(:,1);

%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [2,3,4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20,21,22]);
rawCellColumns = raw(:, 13);


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Allocate imported array to column variable names
position.GPStime = dates{:, 1};
position.GPSweek = cell2mat(rawNumericColumns(:, 1));
position.GPStow = cell2mat(rawNumericColumns(:, 2));
position.Latitude = cell2mat(rawNumericColumns(:, 3));
position.Longitude = cell2mat(rawNumericColumns(:, 4));
position.hellips = cell2mat(rawNumericColumns(:, 5));
position.ECEFX = cell2mat(rawNumericColumns(:, 6));
position.ECEFY = cell2mat(rawNumericColumns(:, 7));
position.ECEFZ = cell2mat(rawNumericColumns(:, 8));
position.UTMNorth = cell2mat(rawNumericColumns(:, 9));
position.UTMEast = cell2mat(rawNumericColumns(:, 10));
position.horthom = cell2mat(rawNumericColumns(:, 11));
position.UTMzone = rawCellColumns(:, 1);
position.numSat = cell2mat(rawNumericColumns(:, 12));
position.HDOP = cell2mat(rawNumericColumns(:, 13));
position.KHDOP = cell2mat(rawNumericColumns(:, 14));
position.LocalNorth = cell2mat(rawNumericColumns(:, 15));
position.LocalEast = cell2mat(rawNumericColumns(:, 16));
position.LocalH = cell2mat(rawNumericColumns(:, 17));
position.Ambiguityfix = cell2mat(rawNumericColumns(:, 18));
position.Successrate = cell2mat(rawNumericColumns(:, 19));
position.ZTD = cell2mat(rawNumericColumns(:, 20));

% For code requiring serial dates (datenum) instead of datetime, uncomment
% the following line(s) below to return the imported dates as datenum(s).

position.GPStime=datenum(position.GPStime);


