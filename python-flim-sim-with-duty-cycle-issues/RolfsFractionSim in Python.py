"""
A package for doing lifetime simulations.  RH, 02-2021
"""
import logging
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit


class PhasorPlot:
    """
    Displays a phasorplot: draw hemicircle with ns markings as defined 
    in lifetimes (np.array), and x/y data in red using PhasorPlot.plot(x_coords, y_coords)
    """

    def __init__(self, omega, lifetimes=None, lifetimeline=None):
        if lifetimes is None:
            self.lifetimes = np.array([0])
        else:
            self.lifetimes = lifetimes
        self.omega = omega
        self.lifetimeline = lifetimeline

    def plot(self, x, y, plot_color):
        """

        :return:
        """
        phase = np.arange(0, np.pi, 0.01)  # draw the hemicircle
        x_circ = .5 + .5 * np.cos(phase)
        y_circ = .5 * np.sin(phase)
        plt.plot(x_circ, y_circ, 'b-')
        plt.plot(x, y, plot_color, markersize=2)  # draw the data points
        x = 1 / ((self.lifetimes * self.omega) ** 2 + 1)
        y = x * (self.lifetimes * self.omega)
        plt.plot(x, y, '.')  # draw the ns markers on hemicircle
        if self.lifetimeline is not None:
            xline = 1 / ((self.lifetimeline * self.omega) ** 2 + 1)
            yline = xline * (self.lifetimeline * self.omega)
            plt.plot(xline, yline, 'k-')

    def fitline(self, x, y):
        x = 1 / ((self.lifetimes * self.omega) ** 2 + 1)
        y = x * (self.lifetimes * self.omega)
        fitval = np.polyfit(x, y, 1)
        # y = ax+b
        # (x-0.5)**2 + y**2 = 0.5  (our semicircle)
        # x**2 - x - 0.25 + (ax+b)**2 = 0
        # x**2 - x  + a**2*x**2 + 2*a*b*x + b**2 - 0.25 = 0
        # (a**2+1)x**2 + (2*a*b-1)x + b**2-0.25 = 0  (ABC formula to solve for x, check for negative y)

class SimFalcon:
    """
    This generates a falcon-style decaying plot based on input photons and plotting parameters
    SimFalcon needs inputs: array with simulated photons, nrOfBins in the exp curve, 
    longest lifetime in the plot, and harmonic(integer 1, 2, 3 etc). Increase the harmonic
    to shift phases anti-clockwise
    """

    def __init__(self, photons, binwidth=0.01, histogramstop=25, harmonic=1):
        self.popt = None
        self.binwidth = binwidth
        self.histogramstop = histogramstop
        self.harmonic = harmonic
        self.photons = photons

    def __str__(self):
        mystring = f'SimFalcon with {len(self.photons)} photons.'
        return mystring

    def showhistogram(self, log=True):
        """

        :return:
        """
        hist, bincenters = self._gethistogram()
        plt.scatter(bincenters, hist)
        if self.popt is not None:
            if len(self.popt) == 3:
                plt.plot(bincenters, self._exponentialfunc(bincenters, *self.popt), 'r-')
            elif len(self.popt) == 5:
                plt.plot(bincenters, self._doubleexponentialfunc(bincenters, *self.popt), 'r-')
        if log:
            plt.yscale('log')
        plt.ylim([1, 1.2*hist.max()])

        plt.xlabel('arrivaltime (ns)')
        plt.ylabel("(#)")

    def setphotons(self, photons):
        """
        Set photons, replacing original photons.
        :param photons:
        :return:
        """
        self.photons = photons

    def onecomponentfit(self):
        """
        Single exponential fit
        :return:
        """
        hist, bincenters = self._gethistogram()
        bounds = (0, np.inf)  # no negative values
        popt, pcov = curve_fit(self._exponentialfunc, bincenters, hist,
                               bounds=bounds, p0=[hist.max(), 1 / 5, 0])
        self.popt = popt
        return popt

    def twocomponentfit(self):
        """

        :return:
        """
        hist, bincenters = self._gethistogram()
        bounds = (0, np.inf)  # no negative values
        popt, pcov = curve_fit(self._doubleexponentialfunc, bincenters, hist,
                               bounds=bounds, p0=[hist.max() / 2, 1 / 5, hist.max() / 2, 1 / 5, 0])
        self.popt = popt
        return popt

    def getphasorcoordinates(self):
        """
        use numpy fft to go from histograms to polar coordinates, as demoed by Rolf in the jptnb plots
        :return:
        """
        hist, bincenters = self._gethistogram()
        res_fft = np.fft.fft(hist / hist.sum())
        y_ph = -np.imag(res_fft[self.harmonic])
        x_ph = np.real(res_fft[self.harmonic])
        return x_ph, y_ph

    def getomega(self):
        """
        Get the angular frequency omega, based on histogramstop (=max range of decay curve)
        This scales the phasor plot hemicircle
        :return:
        """
        return (2 * np.pi * self.harmonic) / self.histogramstop

    # def showphasor(self, lifetimes=np.arange(0, 6, 1), lifetimeline=None):
    #     """
    #   THIS copies the class Phasorplot and can be removed
    #     :return:
    #     """
    #     phase = np.arange(0, np.pi, 0.01)
    #     x_circ = .5 + .5 * np.cos(phase)
    #     y_circ = .5 * np.sin(phase)
    #     plt.plot(x_circ, y_circ, 'b-')
    #     x, y = self.getphasorcoordinates()
    #     plt.plot(x, y, 'ro')
    #     omega = self.getomega()
    #     x = 1 / ((lifetimes * omega) ** 2 + 1)
    #     y = x * (lifetimes * omega)
    #     plt.plot(x, y, '.')
    #     if lifetimeline is not None:
    #         xline = 1 / ((lifetimeline * omega) ** 2 + 1)
    #         yline = xline * (lifetimeline * omega)
    #         plt.plot(xline, yline, 'k-')

    @staticmethod
    def _exponentialfunc(x, a, b, c):
        return a * np.exp(-b * x) + c

    @staticmethod
    def _doubleexponentialfunc(x, a, b, c, d, e):
        return a * np.exp(-b * x) + c * np.exp(-d * x) + e

    def _gethistogram(self):
        """
        uses the np.histogram method to compute a histogram from an array of photon arrival times
        and returns the bincenters as well as the amplitudes
        :return:
        """        
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
        self._normalize_fractions()  # fractions can be entered as arb quantities and are normalized to 100% here

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
            npht[i] = (int(fraction * number_of_photons))     # determine how many photons to simulate for each of the fractions
        npht[-1] = int(number_of_photons - npht[0:-1].sum())
        pht = np.empty(int(number_of_photons), dtype=np.float64)
        ptr = npht.cumsum()
        ptr = np.insert(ptr, 0, 0)
        for i, lifetime in enumerate(self.lifetimes):
            pht[ptr[i]:ptr[i + 1]] = rng.exponential(scale=lifetime, size=npht[i])
        return pht, npht
        # in the end, you generate 4 exp decays, calculate what fractions of photons goes in each,
        # and then simulate them with rng.exponential(Tau, size) and add them together. The 
        #pointer construction is supposed to make that faster

    def set_fraction(self, fractions, quenching=None):
        """
        Normalize the fractions to 1 if quenching=none, else calculate quenching
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
        for i, quenche in enumerate(quenching):  # for each of the Tau's, do:
            self.fractions[i] = self.fractions_o[i] * (1 - quenche)
            self.lifetimes[i] = self.lifetimes_o[i] * (1 - quenche)
        self._normalize_fractions()

    def _normalize_fractions(self):
        total = 0
        for fraction in self.fractions:
            total += fraction

        for i, fraction in enumerate(self.fractions):
            self.fractions[i] = fraction / total


# ---------------------------------------------<<<<<<< start of model: EPAC sensors
# Simple Fraction model with one donor that is converted in another (e.g. binary FRET sensor).
# Long and short AF fractions are added in the indicated fractions.
# note that fractions can add up to any number, they are normalized within the class
# in this model, fractions are changing so we call SimSample.set_fraction(fractions, quenching vector)

lifetimes = [2.3, 2.3, 1.5, 1.0]
fractions = [50, 40, 35, 0]
fractionnames = ['Epac bound', 'Epac unbound', 'AF long', 'AF short']
simSample = SimSample(lifetimes, fractions, fractionnames)
print(simSample)

qv = [0, 1, 0, 0]  # this is used to calculate the dye brightness when quenched by FRET
# qv=[0,0,0,0]
simSample.set_quenching(qv)
print("after set_quenching: ", simSample)

fraction = np.linspace(0, 100, 20)  # fraction is in %, i.e. 0-100
simFalcon = SimFalcon([0])
x_coords = []
y_coords = []

for f in fraction:  # this loop generates the individual datapoints for different fractions
    fractions[0] = f
    fractions[1] = 100 - f
    simSample.set_fraction(fractions, qv)
    photons, n_photons_per_Tau = simSample.generate_photons(5e4)
    simFalcon.setphotons(photons)
    x, y = simFalcon.getphasorcoordinates()
    x_coords.append(x)
    y_coords.append(y)

simFalcon.showhistogram()  # data are based on the last run of the fraction-iteration loop
plt.show()
simFalcon.showhistogram(log=False)
plt.show()

Omega = simFalcon.getomega()
phasorPlot = PhasorPlot(Omega, np.linspace(0, 10, 11), lifetimeline=None)
plot_color = 'ro'
phasorPlot.plot(x_coords, y_coords, plot_color)
plt.show()

# ------------------------------------------<<<<<<start of model2: quenching model
# Simple quanching model with one dye that is quenched (e.g. pH or iodide changes) and the lifetime
# is shorted accordingly. Longe and short AF fractions are added in the indicated fractions
# note that fractions can add up to any number, they are normalized in the class
# in this model, fraction is constant and Tau changes, so we call SimSample.set_quenching(quenching vector)

lifetimes = [2.3, 1.5, 0.2]
fractions = [80, 40, 0]
fractionnames = ['donor', 'AF long', 'AF short']
simulated_photons = 1e5
quenching = np.linspace(0, 1, 100)
simSample = SimSample(lifetimes, fractions, fractionnames)
print(simSample)
simFalcon = SimFalcon([0])
x_coords = []
y_coords = []
for q in quenching:  # this loop generates the individual datapoints for different lifetimes
    qv = [q, 0, 0]  # the donor is quenching, the AF components are not
    simSample.set_quenching(qv)
    photons, npht = simSample.generate_photons(simulated_photons)
    simFalcon.setphotons(photons)
    x, y = simFalcon.getphasorcoordinates()
    x_coords.append(x)
    y_coords.append(y)

simFalcon.showhistogram(log=False)  # data are based on the last run of the fraction iteration loop
plt.show()
simFalcon.showhistogram()
plt.show()

phasorPlot = PhasorPlot(simFalcon.getomega(), np.array([0, 1, 2, 3, 4, 5]))
plot_color = 'go'
phasorPlot.plot(x_coords, y_coords, plot_color)
plt.show()

# ------------------------------------------<<<<<<start of model2B: quenching model, sensitivity analysis
# Simple quanching model with one dye that is quenched (e.g. pH or iodide changes) and the lifetime
# is shorted accordingly. Longe and short AF fractions are added in the indicated fractions
# note that fractions can add up to any number, they are normalized in the class
# in this model, fraction is constant and Tau changes, so we call SimSample.set_quenching(quenching vector)
# this one iterates over several parameters for sensitivity analysis

lifetimes = [4.0, 1.0, 0.2]
fractions = [80, 10, 10]
fractionnames = ['donor', 'AF long', 'AF short']
plot_colors = ['ro', 'go', 'bo', 'co', 'mo', 'yo']
quenching = np.linspace(0, 1, 100)
phasorPlot = PhasorPlot(simFalcon.getomega(), np.array([0, 1, 2, 3, 4, 5]))

for run, plot_color in enumerate(plot_colors):

    simSample = SimSample(lifetimes, fractions, fractionnames)
    print(simSample)
    simFalcon = SimFalcon([0])
    x_coords = []
    y_coords = []
    for q in quenching:  # this loop generates the individual datapoints for different lifetimes
        qv = [q, 0, 0]  # the donor is quenching, the AF components are not
        simSample.set_quenching(qv)
        photons, npht = simSample.generate_photons(1e5)
        simFalcon.setphotons(photons)
        x, y = simFalcon.getphasorcoordinates()
        x_coords.append(x)
        y_coords.append(y)

    plot_color = plot_colors[run]
    phasorPlot.plot(x_coords, y_coords, plot_color)
    fractions[0] = fractions[0] + 10  # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< vary this param
plt.show()

# ---------------------------------------------<<<<<<< start of model 1B: EPAC sensors with sensitivity
# Simple Fraction model with one donor that is converted in another (e.g. binary FRET sensor).
# Long and short AF fractions are added in the indicated fractions.
# note that fractions can add up to any number, they are normalized within the class
# in this model, fractions are changing so we call SimSample.set_fraction(fractions, quenching vector)

lifetimes = [3.6, 1.8, 6.0, 0.5]
fractionnames = ['Epac bound', 'Epac unbound', 'AF long', 'AF short']
plot_colors = ['ro', 'go', 'bo', 'co', 'mo', 'yo']
fraction = np.linspace(0, 100, 101)  # fraction is in %, i.e. 0-100, of the epac sensor (first 2 taus)
phasorPlot = PhasorPlot(Omega, np.linspace(0, 10, 11), lifetimeline=None)
qv = [0.15, 0.555, 0, 0]  # this is used to calculate the dye brightness whith quenchingfactor by FRET
fractions = [50, 40, 35, 10]
g = fractions[2]
h = fractions[3]

for run, plot_color in enumerate(plot_colors):
    print("fractions:  ", fractions)
    simSample = SimSample(lifetimes, fractions, fractionnames)
    simFalcon = SimFalcon([0])
    x_coords = []
    y_coords = []

    simSample.set_quenching(qv)
    print(simSample)

    for f in fraction:  # this loop generates the individual datapoints for different fractions
        fractions = [f, 100 - f, g,h]
        simSample.set_fraction(fractions, qv)
        photons, n_photons_per_Tau = simSample.generate_photons(5e4)
        simFalcon.setphotons(photons)
        x, y = simFalcon.getphasorcoordinates()
        x_coords.append(x)
        y_coords.append(y)

    Omega = simFalcon.getomega()

    plot_color = plot_colors[run]
    phasorPlot.plot(x_coords, y_coords, plot_color)
    # lifetimes[0]=lifetimes[0]+0.3
    g = g + 20
    # h=h+20
