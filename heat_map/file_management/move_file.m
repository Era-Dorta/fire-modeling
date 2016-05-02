function move_file( origin, destiny )
% Tries to move a file from origin to destiny
if(exist(origin, 'file'))
    if(movefile(origin,destiny) == 1)
        disp([origin ' saved in ' destiny]);
    else
        disp([origin ' could not be moved from current location']);
    end
end
end

