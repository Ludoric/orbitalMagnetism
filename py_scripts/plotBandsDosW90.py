import matplotlib.pyplot as plt
import numpy as np
import bandplot_kpoints as kp
import matplotlib as mpl


mpl.rcParams['savefig.format'] = 'pdf'


def main():
    plotBandsDosW90('GdN_W_up', 'GdN_W_dw', 0, 'FCC', dos_clip=55,
                    ylim=(-10, 10), outName='GdN_W_W90_Bands+DOS.pdf')
    # plotBandsDosW90('SmN_M_up', 'SmN_M_dw', 9.8114, 'FCC', dos_clip=55,
    #                 ylim=(-15, 15), outName='SmN_M_W90_Bands+DOS.pdf')
    plotJdosW90('GdN_W_up', 'GdN_W_dw', 13.9718, 'FCC', dos_clip=55,
                outName='GdN_W_W90_JDOS.pdf')

    plt.show()


def plotBandsDosW90(fup, fdw, fermi, cell, *, dos_clip=None,
                    ylim=(None, None), outName=None):
    f, (ax1, ax2) = plt.subplots(
        ncols=2, sharey=True, figsize=(12, 6),
        gridspec_kw={'width_ratios': [3, 1]})

    kpath = np.loadtxt(fup+'-path.kpt', skiprows=1, usecols=(0, 1, 2))

    bnd_up = np.loadtxt(fup+'-bands.dat').T
    bnd_dw = np.loadtxt(fdw+'-bands.dat').T
    dos_up = np.loadtxt(fup+'-dos.dat').T
    dos_dw = np.loadtxt(fdw+'-dos.dat').T
    bnd_up[1] -= fermi
    bnd_dw[1] -= fermi
    dos_up[0] -= fermi
    dos_dw[0] -= fermi

    horiz = np.linspace(bnd_up[0].min(), bnd_up[0].max(), kpath.shape[0])
    insertionLocs = (np.argwhere(np.diff(bnd_up[0]) < 0)+1).flat
    bnd_up = np.array((np.insert(bnd_up[0], insertionLocs, np.nan),
                       np.insert(bnd_up[1], insertionLocs, np.nan)))
    bnd_dw = np.array((np.insert(bnd_dw[0], insertionLocs, np.nan),
                       np.insert(bnd_dw[1], insertionLocs, np.nan)))

    ax1.plot(bnd_up[0], bnd_up[1], '-r', zorder=1)
    ax1.plot(bnd_dw[0], bnd_dw[1], ':b', zorder=2)
    ax2.plot(dos_up[1], dos_up[0], '-r', zorder=1, label='Majority Spin (↑)')
    ax2.plot(dos_dw[1], dos_dw[0], ':b', zorder=2, label='Minority Spin (↓)')
    ax2.fill_betweenx(dos_up[0], dos_up[1], alpha=0.3, color='r', zorder=1)
    ax2.fill_betweenx(dos_dw[0], dos_dw[1], alpha=0.3, color='b', zorder=2)

    # Add the BZ critical points
    kpoints_x, kpoints_n = [], []
    for h, c in zip(horiz, kpath):
        if kpoint := kp.nameFromCrystal(c, cell):
            kpoints_x.append(h)
            kpoints_n.append(kpoint)
    ax1.set_ylim(ylim)
    ax1.set_xticks(kpoints_x)
    ax1.set_xticklabels(kpoints_n)
    ax1.grid(axis='x', color='k', linewidth=1, linestyle='-')
    ax1.tick_params(axis='x', color='k', width=1)  # length=16,
    ax1.margins(x=0)
    ax1.tick_params(axis='y', color='k', width=1, direction='out')
    ax1.axhline(0, ls='--', c='k', lw=1, zorder=0)  # line at zero
    ax1.set_ylabel('Energy [eV]')
    ax2.set_xlim(0, dos_clip)
    ax2.axhline(0, ls='--', c='k', lw=1, zorder=0)  # line at zero
    ax2.set_xticks([])
    # ax2.set_yticks([])
    ax2.tick_params(axis='y', color='k', width=1, length=0,
                    direction='out')  # length=16,
    ax2.set_xlabel('DOS [Arb. Units]')
    ax2.legend()

    f.tight_layout()
    f.subplots_adjust(wspace=0)

    if outName:
        f.savefig(outName, bbox_inches='tight')


def plotJdosW90(fup, fdw, fermi, cell, *, dos_clip=None,
                outName=None):
    f, (ax1) = plt.subplots(
        ncols=1, sharey=True, figsize=(9, 6))

    dos_up = np.loadtxt(fup+'-jdos.dat').T
    dos_dw = np.loadtxt(fdw+'-jdos.dat').T

    # dos_up[0] -= fermi
    # dos_dw[0] -= fermi

    ax1.plot(dos_up[0], dos_up[1], '-r', zorder=1, label='Majority Spin (↑)')
    ax1.plot(dos_dw[0], dos_dw[1], ':b', zorder=2, label='Minority Spin (↓)')
    ax1.fill_between(dos_up[0], dos_up[1], alpha=0.3, color='r', zorder=1)
    ax1.fill_between(dos_dw[0], dos_dw[1], alpha=0.3, color='b', zorder=2)

    # Add the BZ critical points

    # ax1.set_ylim(ylim)
    # ax1.set_xticks(kpoints_x)
    # ax1.set_xticklabels(kpoints_n)
    # ax1.grid(axis='x', color='k', linewidth=1, linestyle='-')
    # ax1.tick_params(axis='x', color='k', width=1)  # length=16,
    # ax1.margins(x=0)
    # ax1.tick_params(axis='y', color='k', width=1, direction='out')
    # ax1.axhline(0, ls='--', c='k', lw=1, zorder=0)  # line at zero
    ax1.set_xlabel('Energy [eV]')
    ax1.set_ylim(0, dos_clip)
    # ax1.axvline(0, ls='--', c='k', lw=1, zorder=0)  # line at zero
    ax1.set_yticks([])
    # ax1.set_xlim(0, None)
    ax1.margins(0, 0)
    # ax2.set_yticks([])
    # ax1.tick_params(axis='y', color='k', width=1, length=0,
    #                 direction='out')  # length=16,
    ax1.set_ylabel('JDOS [Arb. Units]')
    ax1.legend()

    f.tight_layout()
    f.subplots_adjust(wspace=0)

    if outName:
        f.savefig(outName, bbox_inches='tight')


if __name__ == '__main__':
    main()
