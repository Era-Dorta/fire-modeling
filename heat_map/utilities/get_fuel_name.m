function [ fuel_name ] = get_fuel_name( fuel_type )
% GET_FUEL_NAME
%[ FUEL_NAME ] = GET_FUEL_NAME( FUEL_TYPE ) Get fuel name from number
%   [ FUEL_NAME ] = GET_FUEL_NAME( FUEL_TYPE ) Given a fuel integer number
%   FUEL_TYPE, a string with the corresponding name is returned in
%   FUEL_NAME, index starts at 0.
%
%   [ FUEL_NAME ] = GET_FUEL_NAME() Returns a string cell array with all
%   the fuel names.

fuel_names = {'BlackBody', 'Propane', 'Acetylene', 'Methane', 'BlueSyn', ...
    'Cu', 'S', 'Li', 'Ba', 'Na', 'Co', 'Sc', 'C', 'H', 'C3H8'};

if nargin == 1
    fuel_name = fuel_names{fuel_type + 1};
else
    fuel_name = fuel_names;
end
end

