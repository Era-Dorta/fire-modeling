function [ fuel_name ] = get_fuel_name( fuel_type )
% GET_FUEL_NAME
%[ FUEL_NAME ] = GET_FUEL_NAME( FUEL_TYPE ) Get fuel name from number
%   [ FUEL_NAME ] = GET_FUEL_NAME( FUEL_TYPE ) Given a fuel integer number
%   FUEL_TYPE, a string with the corresponding name is returned in
%   FUEL_NAME
fuel_names = {'BlackBody', 'Propane', 'Acetylene', 'Methane', 'BlueSyn', ...
    'Cu', 'S', 'Li', 'Ba', 'Na', 'Co', 'Sc', 'C', 'H', 'C3H8'};
fuel_name = fuel_names{fuel_type + 1};
end

