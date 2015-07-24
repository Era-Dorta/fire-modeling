import sys
from collections import namedtuple

# Matplotlib, http://matplotlib.org/ 
from pylab import show, plot 

# http://hitran.org/static/hapi/hapi.py
from hapi import db_begin, select, fetch, absorptionCoefficient_Lorentz 

MoleculeType = namedtuple("MoleculeType", "name number isotope")

# List of molecules to be used
molecules = [MoleculeType('H2O', 1, 1)]

db_begin('data')  # Creates or gets access to database data

# Wavelengths of interest (the visible range) in nanometres 
min_lambda = 400.0
max_lambda = 700.0

# To cm
min_lambda = min_lambda * 1e-7;
max_lambda = max_lambda * 1e-7;

# Into frequencies, truncate to int to get usable indices for the database
min_f = int(1.0 / max_lambda)
max_f = int(1.0 / min_lambda) + 1

print "min_f is " + str(min_f)
print "max_f is " + str(max_f)

for molecule in molecules:
    needs_download = False
    try:
        # Check if the current molecule is already in the local data base
        select(molecule.name, Output=False)
    except KeyError, e:
        needs_download = True
        
    if needs_download:
        try:
            # Downloads data from the HITRAN site
            fetch(molecule.name, molecule.number, molecule.isotope, min_f, max_f)  
        except Exception:
            error_str = "Could not download data for " + str(molecule) + " in range [" 
            error_str += str(min_f) + ", " + str(max_f) + "]"
            print error_str
            sys.exit(-1)
        
    nu, coef = absorptionCoefficient_Lorentz(SourceTables=molecule.name)
    print "nu is " + str(nu)
    print "coefs are " + str(coef)
    plot(nu, coef)
    show()