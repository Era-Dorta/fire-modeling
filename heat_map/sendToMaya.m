function status = sendToMaya( command, sendScript )
 status = system(['echo "' command ';" | ' sendScript]);
 status = status == 0;
end

