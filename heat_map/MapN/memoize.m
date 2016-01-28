function fmem = memoize(f, arrayInput)
%MEMOIZE stores function results to avoid recalculation
%   FMEM = MEMOIZE(F) accepts a function handle, F, and returns a function
%   handle to a memoized version of the same function. The following
%   restrictions apply to the input function:
%
%   - each argument to F must be a scalar numerical value or a string
%   - F must be called with at least one argument
%   - each argument should have a consistent type (see MapN for the
%       detailed restrictions on types in the argument list)
%   - nargout(F) must be positive, and when called F must actually return
%       this number of results
%   - F should not have side-effects (that matter)
%
% F may have a variable number of arguments.
%
% The first time FMEM is called with a given argument list, F is called to
% compute the results, which are returned and also stored. If FMEM is
% called again with the same argument list, the stored results are
% returned.
%
% Example
%
%   existM = memoize(@exist);
%
%   existM(matlabroot)
%   existM(matlabroot, 'dir')   % existM is used just like exist
%
% Calling existM may be faster than calling exist, especially for finding
% out out about disk files, but the results from existM will be out of date
% if there are changes between calls with the same arguments.
%

% Copyright David Young 2011, Garoe Dorta-Perez 2016

if(nargin < 1)
    error('Not enough input arguments.');
end

store = containers.Map();
nout = nargout(f);

if nout == 1
    fmem = @memo1;
elseif nout > 1
    fmem = @memoN;
else
    fmem = @memo1;
    warning('Memoize:variableNargout', ['Could not determine number of' ...
        ' outputs, assuming there is only one']);
end

if(nargin == 1)
    arrayInput = false;
end

if arrayInput
    if(nargin(f) > 1)
        error(['Cache for function with array inputs only supports ' ...
            'functions with a single input variable.']);
    end
    
    if(isequal(fmem, @memo1))
        fmem = @memo1arr;
    else
        fmem = @memoNarr;
    end
end

% One result returned, so can be stored as is
    function v = memo1(varargin)
        if isKey(store, varargin{:})
            v = store(varargin{:});
        else
            v = f(varargin{:});
            store(varargin{:}) = v;
        end
    end

% One result returned, multiple input so can be stored as is
    function v = memo1arr(varargin)
        % TODO String conversion is slow, but due to the Pidgeonhole
        % principle converting to a a unique double value is not posible
        % TODO Implement max size and LRU policy, see
        % https://github.com/lamerman/cpp-lru-cache
        
        % Since our input is always an array, convert it to string to be
        % used as key
        key = num2str(varargin{:});
        if isKey(store, key)
            v = store(key);
        else
            v = f(varargin{:});
            store(key) = v;
        end
    end


% Wraps multiple results up into a cell array for storage
    function varargout = memoN(varargin)
        if isKey(store, varargin{:})
            result = store(varargin{:});
        else
            [result{1:nout}] = f(varargin{:});
            store(varargin{:}) = result;
        end
        varargout = result(1:nargout);
    end

% Wraps multiple results up into a cell array for storage
    function varargout = memoNarr(varargin)
        key = num2str(varargin{:});
        if isKey(store, key)
            result = store(key);
        else
            [result{1:nout}] = f(varargin{:});
            store(key) = result;
        end
        varargout = result(1:nargout);
    end

end