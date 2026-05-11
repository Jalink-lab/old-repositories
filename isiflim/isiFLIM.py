"""
Specific scripts for isiFLIM.
Can be added to fdFLIM when it does not need to be secret anymore.
-
- PhiModDC_uneq
"""
import numpy as np


def phimoddc_uneq(stack, phases, axis=2):
    """
    Based on formula 20 from
    "Fluorescence lifetime imaging microscopy: Pixel‐by‐pixel analysis of phase‐modulation data" by Gadella et al.
    https://doi.org/10.1002/1361-6374(199409)2:3<139::AID-BIO4>3.0.CO;2-T

    :param stack:
    :param axis:
    :param phases:
    :return:
    """
    # generate the matrix
    M = np.zeros((3, 3), dtype=np.float)
    for ph in phases:
        M[0, 0] += np.sin(ph) ** 2
        M[0, 1] += np.sin(2 * ph)
        M[0, 2] += np.sin(ph)
        M[1, 1] += np.cos(ph) ** 2
        M[1, 2] += np.cos(ph)
    M[0, 1] /= 2
    M[1, 0] = M[0, 1]
    M[2, 0] = M[0, 1]
    M[2, 1] = M[1, 2]
    M[3, 3] = len(phases)
    Minv = np.inv(M)
    # process the stack
    s = stack.shape
    stack = stack.swapaxes(len(s) - 1, axis)  # put phase at the end
    axis = len(s) - 1
    fs = np.sum(stack * np.sin(phases), axis=axis)
    fc = np.sum(stack * np.cos(phases), axis=axis)
    f0 = stack.sum(axis=axis)
    b0 = Minv[0, 0] * fs + Minv[0, 1] * fc + Minv[0, 2] * f0
    b1 = Minv[1, 0] * fs + Minv[1, 1] * fc + Minv[1, 2] * f0
    b2 = Minv[2, 0] * fs + Minv[2, 1] * fc + Minv[2, 2] * f0

    mod = np.sqrt(b0 ** 2 + b1 ** 2)/b2
    phi = np.arctan2(b1, b0)
    dc = b2

    return phi, mod, dc
