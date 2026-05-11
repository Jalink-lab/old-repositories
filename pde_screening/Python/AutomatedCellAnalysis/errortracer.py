"""
This can probably be done by python itself as well, but for now I quickly write a error tracer
"""
import numpy as np
from pathlib import Path


class ErrorTracer:
    """
    A class that stores the errors
    Example:
        ertr = ErrorTracer(100)  # Creates a tracer for 100 entries
        myError = ertr.newerror("It ate my homework!")  # create a new error and store a reference to it
        mySecondError = ertr.newerror("It just failed!")  # create a new error and store a reference to it
        ertr.seterror(20, myError)  # sets the error to entry 20 to be myError
        ertr.haserror(20)  # will return true
        ertr.whaterror(20)  # will return ["It ate my homework!"]
    """
    def __init__(self, totalnr):
        self.ids = np.zeros(totalnr, dtype='uint32')
        self.errors = []
        self.eN = -1

    def newerror(self, name):
        self.errors.append(name)
        self.eN += 1
        return self.eN

    def seterror(self, idx, errornumber):
        if errornumber > len(self.errors):
            print("Error name not yet known. Please define first with new-error.")
            return
        self.ids[idx] += 2 ** errornumber

    def geterror(self, idx):
        return self.ids[idx]

    def savetxt(self, path):
        np.savetxt(path, self.ids, fmt='%i', delimiter="\t")

    def haserror(self, idx):
        return self.ids[idx] > 0

    def errorfree(self):
        return self.ids == 0

    def whaterror(self, idx):
        val = self.ids[idx]
        errors = []
        for i in range(self.eN + 1):
            if val & (1 << i):
                errors.append(self.errors[i])
        return errors
