function [areEqual] = isequalFncCell( inFnc, inFncCell )
%ISEQUALFNCCELL Function name comparison
%   ARE_EQUAL = ISEQUALFNCCELL(IN_FNC, IN_FNC_CELL) Given a function handle
%   IN_FNC and a cell of function handles IN_FNC_CELL. ISEQUALFNCCELL
%   returns in ARE_EQUAL true if any of the function handles point to the
%   same function and false otherwise

if ~iscell(inFncCell)
    error('inFncCell must be a cell');
end

if iscell(inFnc)
    inFnc = inFnc{1};
end

if ~isa(inFnc,'function_handle')
    error('inFnc must be a function handle');
end

areEqual = false;
for i=1:numel(inFncCell)
    if ~isa(inFncCell{i},'function_handle')
        error('inFncCell must contain only function handles');
    end
    
    if isequal(inFnc, inFncCell{i})
        areEqual = true;
        return;
    end
end

end

