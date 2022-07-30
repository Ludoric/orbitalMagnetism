#!/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
import bandplot_kpoints as kp
from pathlib import Path
import re

mpl.rcParams["savefig.format"] = 'pdf'


def readBandFile(fname, zeroPoint=0):
    """
        zeroPoint will usually be the Fermi energy
    """
    nbnd = nks = 0
    dat = []
    with open(fname, 'r') as f:
        line = f.readline().split()
        for i in range(len(line)):
            if 'nbnd' in line[i]:
                nbnd = int(line[i+1].strip(','))
            elif 'nks' in line[i]:
                nks = int(line[i+1].strip(','))
        for _ in range(nks):
            values = []
            while len(values) < nbnd + 3:
                values.extend(f.readline().split())
            dat.append(np.array(values, float))
    dat = np.array(dat)
    dat[:, 3:] -= zeroPoint
    return dat  # , nks, nbnd


def readFermiFile(fname, index_col=0, sep='\t'):
    """
        The fermi file is a (usually) .tsv file
        Each row associates some paramter of a file name to a fermi energy
        The first line of the file must give the names for the columns
        The loaded file is returned as a nested dictionary against index_col
    """
    with open(fname, 'r') as f:
        names = f.readline().strip('\r\n').split(sep)
        # datd = {float(l.split(sep)[0]):
        #         {zip(names[1:],map(float, l.split(sep)[1:]))}
        #         for l in f.readlines()}
        dat = np.array([np.array(ln.strip('\r\n').split(sep))
                        for ln in f.readlines()])
    dat[dat == ''] = 'NaN'
    dat = dat.astype(float)
    # datd = {l[0]: {zip(names[1:], l[1:])} for l in dat}
    dname = names.pop(index_col)
    l1keys = dat[:, index_col]
    l2values = np.delete(dat, index_col, axis=1)
    datd = {l1k: dict(zip(names, l2v)) for l1k, l2v in zip(l1keys, l2values)}
    return dname, datd


def loadLotsOfData(bandFName, zeroFN=None, zeroN='FermiE', orbital='Gd4f'):
    if zeroFN is not None:
        _, fD = readFermiFile(zeroFN)
    bandD = {}
    for file in Path(bandFName).glob('*.bands'):
        fstr = str(file.as_posix())
        if 'S2' in fstr:
            spin = '↓'
        elif 'S1' in fstr:
            spin = '↑'
        else:
            print('Spin not known from file name, defaulting to ↑')
            spin = '↑'
        fparts = re.split('/|_|-', fstr)
        HU = float(fparts[fparts.index(orbital)+1])
        if zeroFN is None:
            bandD.setdefault(HU, {})[spin] = readBandFile(file)
        else:
            bandD.setdefault(HU, {})[spin] = readBandFile(file, fD[HU][zeroN])
    return bandD


def removeDuplicateLabels(ax):
    handles, labels = ax.get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    ax.legend(by_label.values(), by_label.keys())


def plotData(datup, datdown=None):
    f = plt.figure()
    ax = f.add_subplot()
    horiz = np.linspace(0, 1, datup.shape[0])
    if datdown is not None:
        if np.array_equal(datup[:, :3], datdown[:, :3]):
            for i in range(3, datdown.shape[1]):
                ax.plot(horiz, datdown[:, i], ':b', zorder=2,
                        label='Minority Spin (↓)')
        else:
            print('Spin up and spin down coordinates do not match.')
            print('\tSpin down data has been ignored')
    for i in range(3, datup.shape[1]):
        ax.plot(horiz, datup[:, i], '-r', zorder=1, label='Majority Spin (↑)')
    kpoints_x = []
    kpoints_n = []
    for h, l in zip(horiz, datup[:, :3]):
        if kpoint := kp.nameFromKvec(l):
            kpoints_x.append(h)
            kpoints_n.append('Γ' if kpoint == 'Gamma' else kpoint)
    ax.set_xticks(kpoints_x)
    ax.set_xticklabels(kpoints_n)
    ax.grid(axis='x', color='k', linewidth=1, linestyle='-')
    ax.tick_params(axis='x', color='k', width=1)  # length=16,
    ax.margins(x=0)
    ax.tick_params(axis='y', color='k', width=1)
    ax.axhline(0, c='k', linewidth=1, zorder=0)
    ax.set_ylabel('Energy [eV]')
    f.tight_layout()
    if datdown is not None:
        removeDuplicateLabels(ax)
    return f, ax


def plotKvsU(bandD, kpoint='Gamma', orbital='Gd4f', individual=False):
    # kindex = [kp.nameFromKvec(r) for r in (bandD.values(), )[0]['↑'][:, :3]
    #           ].index(kpoint)
    for kindex, r in enumerate(tuple(bandD.values())[0]['↑'][:, :3]):
        if kp.nameFromKvec(r) == kpoint:
            break
    Sup, Sdo, Hs = [], [], []
    for HU, S in sorted(bandD.items()):
        if individual:
            plotData(S['↑'], S.get('↓'))
        Sup.append(S['↑'][kindex, 3:])
        Sdo.append(S['↓'][kindex, 3:])
        Hs.append(HU)
    # sort all three arrays by the Hubbard U parameter
    Sup, Sdo, Hs = np.array(Sup), np.array(Sdo), np.array(Hs)
    arginds = Hs.argsort()
    Sup, Sdo, Hs = Sup[arginds], Sdo[arginds], Hs[arginds]

    f = plt.figure()
    ax = f.add_subplot()
    ax.plot(Hs, Sup[:, 3:], '-r', zorder=1, label='Majority Spin (↑)')
    ax.plot(Hs, Sdo[:, 3:], ':b', zorder=2, label='Minority Spin (↓)')
    removeDuplicateLabels(ax)
    ax.set_ylabel('Energy [eV]')
    ax.set_xlabel(f'Hubbard U for {orbital} [eV]')
    ax.margins(x=0)
    f.tight_layout()
    return f, ax


if __name__ == '__main__':
    # dat = readBandFile('bands_out_GdN-FCC.bands')
    # dup = readBandFile('bands2_GdN-FCC-S1.bands')
    # ddown = readBandFile('bands2_GdN-FCC-S2.bands')
    # dup = readBandFile('bands-up_GdN-FCC.bands')
    # ddown = readBandFile('bands-down_GdN-FCC.bands')
    # plotData(dup, ddown)
    bandD = loadLotsOfData('../tooBig/hubbardOut/',
                           '../tooBig/hubbardOut/fermi.tsv')
    plotKvsU(bandD, kpoint='Gamma', individual=False)
    # thus if the Gd4f band is 7.8eV below the fermi level, U should be 8.4eV
    # (from GdN THIN FILMS: BULK AND LOCAL ELECTRONIC...)

    plt.show()
