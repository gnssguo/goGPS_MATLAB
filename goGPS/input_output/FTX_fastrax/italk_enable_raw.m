function [out] = italk_enable_raw(serialObj, tran_id)

% SYNTAX:
%   [out] = italk_enable_raw(serialObj, tran_id);
%
% INPUT:
%   serialObj = serial Object identifier
%   tran_id = transaction ID
%
% OUTPUT:
%   out = receiver reply
%
% DESCRIPTION:
%   ITALK configuration message.

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
%  Contributors:     Ivan Reguzzoni, ...
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

%----------------------------------------------------------------------------------------------
% FTX MESSAGE HEADER
%----------------------------------------------------------------------------------------------

header1 = '3C';      % header (hexadecimal value) - 60 (decimal value) - ascii '<'
header2 = '21';      % header (hexadecimal value) - 33 (decimal value) - ascii '!'

source = '42';       % source information
destination = '20';  % destination information

msg_id   = '47';     % message id

payload  = ['01';'00';'01';'00';'12';'C0';'0C';'02';'00';'00'];    % payload (bitmask to enable only TRACK, PSEUDO and RAW EPHEMERIS)

pay_size = size(payload,1)/2;               % payload size

payload_bin = dec2bin(hex2dec(payload),8)';
payload_bin = payload_bin(:)';
payload_dec = hex2dec(payload);

checksum = checksumFTX(payload_bin,pay_size);    % checksum

end1 = '3E';

codeHEX = [header1; header2; source; destination; msg_id];
codeDEC = hex2dec(codeHEX);
codeDEC = [codeDEC; tran_id; pay_size; payload_dec; fbin2dec(checksum(1:8)); fbin2dec(checksum(9:16)); hex2dec(end1) ];

%serial port checking
reply_1 = get(serialObj,'BytesAvailable');

if (reply_1 ~= 0)
    %clear the serial port (data not decoded)
    reply = fread(serialObj, reply_1, 'uint8'); %#ok<NASGU>
end

% send message
fwrite(serialObj, codeDEC, 'uint8', 'async');

% wait for the asynchronous writing to finish
pause(0.5)

[out] = fastrax_check_ACK(serialObj, tran_id, msg_id, payload_dec);
