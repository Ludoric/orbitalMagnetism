#!/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt
import bandplot_kpoints as kp


def readBandFile(fname):
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
    return np.array(dat)  # , nks, nbnd


def plotData(datup, datdown=None):
    f = plt.figure()
    ax = f.add_subplot()
    horiz = np.linspace(0, 1, datup.shape[0])
    if datdown is not None:
        if np.array_equal(datup[:, :3], datdown[:, :3]):
            for i in range(3, datdown.shape[1]):
                ax.plot(horiz, datdown[:, i], ':b', label='Minority Spin (↓)')
        else:
            print('Spin up and spin down coordinates do not match.')
            print('\tSpin down data has been ignored')
    for i in range(3, datup.shape[1]):
        ax.plot(horiz, datup[:, i], '-r', label='Majority Spin (↑)')  # '.k'
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
    ax.set_xlim(0, 1)
    ax.tick_params(axis='y', color='k', width=1)
    ax.axhline(0, c='k', linewidth=1, zorder=0)
    ax.set_ylabel('Energy [eV]')
    if datdown is not None:
        handles, labels = ax.get_legend_handles_labels()
        by_label = dict(zip(labels, handles))
        ax.legend(by_label.values(), by_label.keys())
    return f, ax


if __name__ == '__main__':
    # dat = readBandFile('bands_out_GdN-FCC.bands')
    dup = readBandFile('bands2_GdN-FCC-S1.bands')
    ddown = readBandFile('bands2_GdN-FCC-S2.bands')
    f, ax = plotData(dup, ddown)
    plt.show()
