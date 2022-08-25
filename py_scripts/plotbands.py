#!/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
import bandplot_kpoints as kp
from pathlib import Path
import re
# import mpl_sqrtaxis

mpl.rcParams['savefig.format'] = 'pdf'


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
        fparts = re.split('/|_', fstr)
        HU = float(fparts[fparts.index(orbital)+1])
        # s = fparts[2][4:8]
        # if s[-1] == '-':
        #     s = s[:-1]
        # HU = float(s)

        if zeroFN is None:
            bandD.setdefault(HU, {})[spin] = readBandFile(file)
        else:
            bandD.setdefault(HU, {})[spin] = readBandFile(file, fD[HU][zeroN])
    return bandD


def readDOS(dosFName, ax=None):
    # energy, dosup, dosdw, idos
    with open(dosFName) as f:
        FermiE = float(f.readline().split()[-2])
        datdos = np.loadtxt(f, unpack=True)
        datdos[0] -= FermiE
    return FermiE, datdos


def removeDuplicateLabels(ax):
    handles, labels = ax.get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    ax.legend(by_label.values(), by_label.keys())


def plotDOS(datdos, ax=None, onY=False):
    if ax:
        f = None
    else:
        f = plt.figure(figsize=(9, 6))
        f.tight_layout()
        ax = f.add_subplot()
    if onY:
        Yup = Ydw = datdos[0]
        Xup = datdos[1]
        Xdw = datdos[2]
    else:
        Xup = Xdw = datdos[0]
        Yup = datdos[1]
        Ydw = datdos[2]
    # energy, dosup, dosdw, idos
    if datdos.shape[0] == 4:
        ax.plot(Xdw, Ydw, ':b', zorder=2, label='Minority Spin (↓)')
    elif datdos.shape[0] != 3:
        print(f"HELP! datdos is the wrong shape! It's {datdos.shape}")
    ax.plot(Xup, Yup, '-r', zorder=1, label='Majority Spin (↑)')
    # ax.plot(datdos[0], datdos[3], '-b', zorder=1, label='idos')
    if onY:
        ax.axhline(y=0, ls='--', c='k', lw=1, zorder=0)
        ax.set_xticks([])
        ax.set_xlabel('DOS')
        ax.set_ylabel('Energy [eV]')
        ax.set_xlim(0, None)
        # ax.set_xscale('log')
    else:
        ax.axvline(x=0, ls='--', c='k', lw=1, zorder=0)
        ax.set_xlabel('Energy [eV]')
        ax.set_ylabel('DOS')
        ax.set_yticks([])
        ax.set_ylim(0, None)
        # ax.set_yscale('log')
    # mpl.scale.register_scale(mpl_sqrtaxis.SquareRootScale)
    # ax.set_yscale('squareroot')
    # ax.set_yticks(np.arange(0, 9, 2)**2)
    # ax.set_yticks(np.arange(0, 8.5, 0.5)**2, minor=True)

    ax.legend()
    return f, ax


def plotBands(cell, datup, datdw=None, ax=None, nolegend=False):
    if ax:
        f = None
    else:
        # f = plt.figure(figsize=(9, 6))
        # f.tight_layout()
        # ax = f.add_subplot()
        f, (ax) = plt.subplots(ncols=1, figsize=(9, 6))
        f.tight_layout()
    horiz = np.linspace(0, 1, datup.shape[0])
    if datdw is not None:
        if np.array_equal(datup[:, :3], datdw[:, :3]):
            for i in range(3, datdw.shape[1]):
                ax.plot(horiz, datdw[:, i], ':b', zorder=2,
                        label='Minority Spin (↓)')
        else:
            print('Spin up and spin down coordinates do not match.')
            print('\tSpin down data has been ignored')
    for i in range(3, datup.shape[1]):
        ax.plot(horiz, datup[:, i], '-r', zorder=1, label='Majority Spin (↑)')
    kpoints_x = []
    kpoints_n = []
    for h, l in zip(horiz, datup[:, :3]):
        if kpoint := kp.nameFromKvec(l, cell):
            kpoints_x.append(h)
            kpoints_n.append(kpoint)
    ax.set_xticks(kpoints_x)
    ax.set_xticklabels(kpoints_n)
    ax.grid(axis='x', color='k', linewidth=1, linestyle='-')
    ax.tick_params(axis='x', color='k', width=1)  # length=16,
    ax.margins(x=0)
    ax.set_ylim(-10, 10)
    ax.tick_params(axis='y', color='k', width=1)
    ax.axhline(0, c='k', linewidth=1, zorder=0)
    ax.set_ylabel('Energy [eV]')
    if datdw is not None and not nolegend:
        removeDuplicateLabels(ax)
    return f, ax


def plotKvsHU(bandD, cell, kpoint='Gamma', orbital='Gd4f', individual=False,
              ax=None):
    # kindex = [kp.nameFromKvec(r) for r in (bandD.values(), )[0]['↑'][:, :3]
    #           ].index(kpoint)
    for kindex, r in enumerate(tuple(bandD.values())[0]['↑'][:, :3]):
        if kp.nameFromKvec(r, cell) == kpoint:
            break
    Sup, Sdw, Hs = [], [], []
    for HU, S in sorted(bandD.items()):
        if individual:
            plotBands(cell, S['↑'], S.get('↓'))
        Sup.append(S['↑'][kindex, 3:])
        Sdw.append(S['↓'][kindex, 3:])
        Hs.append(HU)
    Sup, Sdw, Hs = np.array(Sup), np.array(Sdw), np.array(Hs)
    # # sort all three arrays by the Hubbard U parameter
    # arginds = Hs.argsort()
    # Sup, Sdw, Hs = Sup[arginds], Sdw[arginds], Hs[arginds]
    # (already sorted by calling sorted(bandD.items()))

    if not ax:
        f = plt.figure(figsize=(9, 6))
        f.tight_layout()
        ax = f.add_subplot()
    ax.plot(Hs, Sup[:, 3:], '-r', zorder=1, label='Majority Spin (↑)')
    ax.plot(Hs, Sdw[:, 3:], ':b', zorder=2, label='Minority Spin (↓)')
    removeDuplicateLabels(ax)
    ax.set_ylim(-10, 10)
    ax.set_ylabel('Energy [eV]')
    ax.set_xlabel(f'Hubbard U for {orbital} [eV]')
    ax.margins(x=0)
    return f, ax


def plotBandgap(bandD, orbital='Gd4f', ax=None):
    Sup, Sdw, Hs = [], [], []
    for HU, S in sorted(bandD.items()):
        vup = S['↑'][:, 3:]
        vdw = S['↓'][:, 3:]
        sup = vup[vup > 0].min() - vup[vup < 0].max()
        sdw = vdw[vdw > 0].min() - vdw[vdw < 0].max()
        Sup.append(sup)
        Sdw.append(sdw)
        Hs.append(HU)
    Sup, Sdw, Hs = np.array(Sup), np.array(Sdw), np.array(Hs)
    # # sort all three arrays by the Hubbard U parameter
    # arginds = Hs.argsort()
    # Sup, Sdw, Hs = Sup[arginds], Sdw[arginds], Hs[arginds]
    # (already sorted by calling sorted(bandD.items()))

    if not ax:
        f = plt.figure(figsize=(9, 6))
        f.tight_layout()
        ax = f.add_subplot()
    ax.plot(Hs, Sup, '-r', zorder=1, label='Majority Spin (↑)')
    ax.plot(Hs, Sdw, ':b', zorder=2, label='Minority Spin (↓)')
    # ax.set_ylim(-10, 10)
    ax.set_ylabel('Energy [eV]')
    ax.set_xlabel(f'Hubbard U for {orbital} [eV]')
    ax.margins(x=0)
    return f, ax


def plotBandsDos(cell, dosFN, bandSupFN, bandSdwFN):
    FermiE, datdos = readDOS(dosFN)
    dup = readBandFile(bandSupFN, zeroPoint=FermiE)
    ddown = readBandFile(bandSdwFN, zeroPoint=FermiE)
    f, (ax1, ax2) = plt.subplots(
        ncols=2, sharey=True, figsize=(12, 6),
        gridspec_kw={'width_ratios': [3, 1]})
    plotBands(cell, dup, ddown, ax=ax1, nolegend=True)
    plotDOS(datdos, ax=ax2, onY=True)
    ax2.set_ylabel(None)
    f.tight_layout()
    f.subplots_adjust(wspace=0)
    return f, (ax1, ax2)


if __name__ == '__main__':
    # dat = readBandFile('bands_out_GdN-FCC.bands')
    # dup = readBandFile('bands2_GdN-FCC-S1.bands')
    # ddown = readBandFile('bands2_GdN-FCC-S2.bands')
    # dup = readBandFile('bands-up_GdN-FCC.bands')
    # ddown = readBandFile('bands-down_GdN-FCC.bands')
    # plotBands(dup, ddown)
    # bandD = loadLotsOfData('./', './fermi.tsv', orbital='Gd-4f')
    # plotKvsHU(bandD, 'FCC', kpoint='Gamma', individual=True, orbital='Gd-4f')
    # thus if the Gd4f band is 7.8eV below the fermi level, U should be 8.4eV
    # (from GdN THIN FILMS: BULK AND LOCAL ELECTRONIC...)
    # plotBandsDos('../tooBig/hubbardOut/H_Gd4f_8.00_GdN-FCC.dos',
    #              '../tooBig/hubbardOut/H_Gd4f_8.00_GdN-FCC-S1.bands',
    #              '../tooBig/hubbardOut/H_Gd4f_8.00_GdN-FCC-S2.bands')
    # bandD = loadLotsOfData('./',
    #                        './fermi.tsv',
    #                        orbital='Gd-5d')
    # plotKvsHU(bandD, kpoint='X', individual=False, orbital='Gd-5d')
    # plotBandgap(bandD, orbital='Gd-5d')

    dup = readBandFile('GdN-S1.bands', zeroPoint=13.9718)
    ddown = readBandFile('GdN-S2.bands', zeroPoint=13.9718)
    # dup = readBandFile('SmN_M-S1.bands', zeroPoint=9.5132)
    # ddown = readBandFile('SmN_M-S2.bands', zeroPoint=9.5132)
    f, ax = plotBands('FCC', dup, ddown)
    ax.set_ylim((-15, 15))
    f.savefig('SmN_W_pw_Bands.pdf', bbox_inches='tight')
    plt.show()

    # SmN - Paramagnetic phase 1.3ev from fermi measured from (5d-sup 5d-sdw)


# keep trying to get wannier to work!!!!
