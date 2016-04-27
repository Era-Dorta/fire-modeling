function assert_valid_range_in_0_1( x )
%ASSERT_VALID_RANGE_IN_0_1 Checks if range is valid
%   ASSERT_VALID_RANGE_IN_0_1(X) Checks if any value in X is Inf
%   Nan, or it is outside of the [0,1] range. If so, it throws an error.

assert(all(~isinf(x)), 'X contains Inf');
assert(all(~isnan(x)), 'X contains NaN');
assert(all(x >= 0), 'X is < 0');
assert(all(x <= 1), 'X is > 1');

end

