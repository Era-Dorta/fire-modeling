%test weights2prob

% Tolerance for float comparison
tol = 0.00001;

%% Test direct no convertion

w = [0.6, 0.2, 0.2];

prob = weights2prob(w);

assert(all(abs(prob - w) < tol), 'Failed with given probabilities');

%% Test inverse no convertion

w = [0.6, 0.2, 0.2];

prob = weights2prob(w, true);

expProb = [0.142857142857143, 0.428571428571429, 0.428571428571429];
assert(all(abs(prob - expProb) < tol), 'Failed with given probabilities inverse');

%% Test direct weight convertion

w = [100, 50, 25];

prob = weights2prob(w);

expProb = [0.571428571428571, 0.285714285714286, 0.142857142857143];
assert(all(abs(prob - expProb) < tol), 'Failed with direct weights');

%% Test inverse weight convertion

w = [100, 50, 25];

prob = weights2prob(w, true);

expProb = [0.142857142857143, 0.285714285714286, 0.571428571428571];
assert(all(abs(prob - expProb) < tol), 'Failed with inverse weights');