"""
A package for doing lifetime simulations
"""
import logging
import numpy as np
import matplotlib.pyplot as plt


class PhasorPlot:
    """
    Displays a phasorplot: hemicircle, x/y data
    """

    def __init__(self, omega, lifetimes=None, lifetimeline=None):
        if lifetimes is None:
            self.lifetimes = np.array([0])
        else:
            self.lifetimes = lifetimes
        self.omega = omega
        self.lifetimeline = lifetimeline

    def plot(self, x, y):
        """

        :return:
        """
        phase = np.arange(0, np.pi, 0.01)
        x_circ = .5 + .5 * np.cos(phase)
        y_circ = .5 * np.sin(phase)
        plt.plot(x_circ, y_circ, 'b-')
        plt.plot(x, y, 'ro')
        x = 1 / ((self.lifetimes * self.omega) ** 2 + 1)
        y = x * (self.lifetimes * self.omega)
        plt.plot(x, y, '.')
        if self.lifetimeline is not None:
            xline = 1 / ((self.lifetimeline * self.omega) ** 2 + 1)
            yline = xline * (self.lifetimeline * self.omega)
            plt.plot(xline, yline, 'k-')


class SimFalcon:
    """
    Simulate the falcon
    """

    def __init__(self, photons, binwidth=0.01, histogramstop=12, harmonic=1):
        self.binwidth = binwidth
        self.histogramstop = histogramstop
        self.harmonic = harmonic
        self.photons = photons

    def __str__(self):
        mystring = f'SimFalcon with {len(self.photons)} photons.'
        return mystring

    def showhistogram(self):
        """

        :return:
        """
        hist, bincenters = self._gethistogram()
        plt.scatter(bincenters, hist)
        plt.xlabel('arrivaltime (ns)')

    def setphotons(self, photons):
        """
        Set photons, replacing original photons.
        :param photons:
        :return:
        """
        self.photons = photons

    def twocomponentfit(self):
        """
        Not yet implemented
        :return:
        """
        return "Sorry, not yet implemented"

    def getphasorcoordinates(self):
        """

        :return:
        """
        hist, bincenters = self._gethistogram()
        res_fft = np.fft.fft(hist / hist.sum())
        y_ph = -np.imag(res_fft[self.harmonic])
        x_ph = np.real(res_fft[self.harmonic])
        return x_ph, y_ph

    def getomega(self):
        """
        Get the angular frequency omega.
        :return:
        """
        return (2 * np.pi * self.harmonic) / self.histogramstop

    def showphasor(self, lifetimes=np.arange(0, 6, 1), lifetimeline=None):
        """

        :return:
        """
        phase = np.arange(0, np.pi, 0.01)
        x_circ = .5 + .5 * np.cos(phase)
        y_circ = .5 * np.sin(phase)
        plt.plot(x_circ, y_circ, 'b-')
        x, y = self.getphasorcoordinates()
        plt.plot(x, y, 'ro')
        omega = self.getomega()
        x = 1 / ((lifetimes * omega) ** 2 + 1)
        y = x * (lifetimes * omega)
        plt.plot(x, y, '.')
        if lifetimeline is not None:
            xline = 1 / ((lifetimeline * omega) ** 2 + 1)
            yline = xline * (lifetimeline * omega)
            plt.plot(xline, yline, 'k-')

    def _gethistogram(self):
        binedges = np.arange(start=0, stop=self.histogramstop, step=self.binwidth)
        hist, binedges = np.histogram(self.photons, bins=binedges, density=False)
        bincenters = binedges[:-1] + np.diff(binedges) / 2
        return hist, bincenters


class SimSample:
    """
    Class to hold the Sample to Simulate
    Can have lifetimes and fractions
    """
    lifetimes_o = []  # Original lifetimes
    fractions_o = []  # Fractions in sample (mol)
    lifetimes = []  # Quenched lifetimes
    fractions = []  # Fractions in emission (photons)
    fractionnames = []
    N = 0  # Nr of lifetimes

    def __init__(self, lifetimes, fractions, fractionnames=None):
        if fractionnames is None:
            self.fractionnames = [str(i) for i, _ in enumerate(lifetimes)]
        elif len(fractionnames) != len(lifetimes):
            logging.error("length of lifetimenames and lifetimes must be equal")
            return
        else:
            self.fractionnames = fractionnames.copy()
        if len(lifetimes) != len(fractions):
            logging.error("length of lifetimes and fractions must be equal")
            return
        self.lifetimes = lifetimes.copy()
        self.fractions = fractions.copy()
        self.lifetimes_o = lifetimes.copy()
        self.fractions_o = fractions.copy()

        self.N = len(lifetimes)
        self._normalize_fractions()

    def __str__(self):
        mystring = 'Sample contains the following lifetimes:'
        for i, lifetime in enumerate(self.lifetimes):
            mystring += f'\n  * {self.fractionnames[i]} : {lifetime:.2f}ns - ' \
                        f'{(self.fractions[i] * 100):.2f}% of photons'
        return mystring

    def generate_photons(self, number_of_photons=1e6, seed=None):
        """
        Generate photons based on the fractions and lifetimes.
        :param seed: seed for the random number generator
        :param number_of_photons:
        :return (photon arrival times, number of photons generated per lifetime)
        """
        rng = np.random.default_rng(seed=seed)
        npht = np.empty(len(self.fractions), dtype=np.uint64)
        for i, fraction in enumerate(self.fractions):
            npht[i] = (int(fraction * number_of_photons))
        npht[-1] = int(number_of_photons - npht[0:-1].sum())
        pht = np.empty(int(number_of_photons), dtype=np.float64)
        ptr = npht.cumsum()
        ptr = np.insert(ptr, 0, 0)
        for i, lifetime in enumerate(self.lifetimes):
            pht[ptr[i]:ptr[i + 1]] = rng.exponential(scale=lifetime, size=npht[i])
        return pht, npht

    def set_fraction(self, fractions, quenching=None):
        """
        Change fraction
        :param fractions:
        :param quenching:
        :return:
        """
        self.fractions_o = fractions
        if quenching is None:
            self.fractions = fractions
            self._normalize_fractions()
        else:
            self.set_quenching(quenching)

    def set_quenching(self, quenching):
        """
        Change lifetime and fraction using a quenching vector
        :param quenching:
        :return:
        """
        if len(quenching) != self.N:
            logging.error("quenching vector was not equal to the number of lifetimes")
            return
        for i, quence in enumerate(quenching):
            self.fractions[i] = self.fractions_o[i] * (1 - quence)
            self.lifetimes[i] = self.lifetimes_o[i] * (1 - quence)
        self._normalize_fractions()

    def _normalize_fractions(self):
        total = 0
        for fraction in self.fractions:
            total += fraction

        for i, fraction in enumerate(self.fractions):
            self.fractions[i] = fraction / total
            
lifetimes = [3.6, 1.8, 6.0, 1.0]
fractions = [50, 40, 50, 5]
fractionnames = ['Epac bound', 'Epac unbound', 'AF long', 'AF short']
simSample = SimSample(lifetimes, fractions, fractionnames)
print(simSample)

qv = [0.15, 0.525,0, 0]
simSample.set_quenching(qv)
print(simSample)

fraction = np.linspace(0,50,51)
simFalcon = SimFalcon([0])
x_coords = []
y_coords = []


for f in fraction:
    fractions = [f, 100-f, 10, 10]
    simSample.set_fraction(fractions, qv)
    photons,npht = simSample.generate_photons(5e4)
    simFalcon.setphotons(photons)
    x,y = simFalcon.getphasorcoordinates()
    x_coords.append(x)
    y_coords.append(y)

simFalcon.showhistogram()
plt.show()

phasorPlot = PhasorPlot(simFalcon.getomega(),np.array([0,1,2,3,4,5,10]))
phasorPlot.plot(x_coords,y_coords)


