import sys
from collections import namedtuple

# Matplotlib, http://matplotlib.org/ 
from pylab import show, plot, figure, close

# http://hitran.org/static/hapi/hapi.py
from hapi import *

MoleculeType = namedtuple("MoleculeType", "name number isotope")

# List of molecules to be used
molecules = []

molecules.append(MoleculeType('H2', 45, 1))
molecules.append(MoleculeType('C2H6', 27, 1))
molecules.append(MoleculeType('C2H2', 26, 1))
molecules.append(MoleculeType('CH4', 6, 1))

db_begin('data')  # Creates or gets access to database data

# Wavelengths of interest (the visible range) in nanometres 
min_lambda = 400.0
max_lambda = 700.0

# Into frequencies 1/cm, truncate to int to get usable indices for the database
min_f = int(1e7 / max_lambda)
max_f = int(1e7 / min_lambda) + 1

print "min_f is " + str(min_f)
print "max_f is " + str(max_f)

for molecule in molecules:
    needs_download = False
    try:
        # Check if the current molecule is already in the local data base
        select(molecule.name, Output=False)
    except KeyError, e:
        needs_download = True
    
    data_available = True
        
    if needs_download:
        try:
            # Downloads data from the HITRAN site
            fetch(molecule.name, molecule.number, molecule.isotope, min_f, max_f)
        except Exception:
            error_str = "Could not download data for " + str(molecule) + " in range [" 
            error_str += str(min_f) + ", " + str(max_f) + "]"
            print error_str
            data_available = False
    
    if data_available:
    #     describeTable(molecule.name)
        nu, sw = getColumns(molecule.name, ['nu', 'sw'])
        
        nu1, coef = absorptionCoefficient_Lorentz(SourceTables=molecule.name)
        nu2, absorp = absorptionSpectrum(nu1, coef)
        nu3, radi = radianceSpectrum(nu1, coef)
            
        # Normalize the intensities
        max_sw = 0
        for i in range(len(sw)):
            if sw[i] > max_sw:
                max_sw = sw[i]
        
        for i in range(len(sw)):
            sw[i] /= max_sw
                        
        # Convert to wavelengths in nm again
        for i in range(len(nu)):
            nu[i] = 1e7 / nu[i]
            
        for i in range(len(nu1)):
            nu1[i] = 1e7 / nu1[i]
        
        for i in range(len(nu2)):
            nu2[i] = 1e7 / nu2[i]
        
        for i in range(len(nu3)):
            nu3[i] = 1e7 / nu3[i]
    
        figure("Spectral Line")
        plot(nu, sw)
        show(block=False)
        
        fig1 = figure("Absorption Coefficients")
        plot(nu1, coef)
        show(block=False)
        
        fig1 = figure("Absorption Spectrum")
        plot(nu2, absorp)
        show(block=False)
        
        fig1 = figure("Emission Spectrum")
        plot(nu3, radi)
        show(block=False)
        
        raw_input("Press Enter to continue...")
        
        close()
        close()
        close()
        close()
