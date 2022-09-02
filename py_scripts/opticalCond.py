import matplotlib.pyplot as plt
import numpy as np
import scipy.constants as c


def main():
    print('Do the thing')



# def plotOpticalCond(fup, fdw, fermi, cell, *, dos_clip=None,
#                 outName=None):
f, (ax1) = plt.subplots(
    ncols=1, sharey=True, figsize=(9, 6))

meas = np.loadtxt('GdN_7k_S1.dat', skiprows=1).T

meas[0] /= c.electron_volt/(c.h * c.c)/100
meas[1] *= 3046/703  # yscale factor
ax1.plot(meas[0], meas[1], '-r', zorder=1, label='Measured Data')


for  orient in ['xx', 'yy', 'zz']:  # , 'xy', 'xz', 'xy'
    calc_up = np.loadtxt(f'GdN_W/GdN_W_up-kubo_S_{orient}.dat').T
    calc_dw = np.loadtxt(f'GdN_W/GdN_W_dw-kubo_S_{orient}.dat').T
    # ax1.plot(calc_up[0], calc_up[1], ':b', zorder=2, label=f'calc_up_{orient}')
    # ax1.plot(calc_dw[0], calc_dw[1], ':g', zorder=2, label=f'calc_dw_{orient}')
    ax1.plot(calc_up[0], calc_up[1]+calc_dw[1], '-b', zorder=2, label=f'calc_{orient}')

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
# ax1.set_ylim(0, dos_clip)
# ax1.axvline(0, ls='--', c='k', lw=1, zorder=0)  # line at zero
ax1.set_yticks([])
ax1.set_xlim(0, 5)
ax1.set_ylim(0, 5000)
ax1.margins(0, 0)
# ax2.set_yticks([])
# ax1.tick_params(axis='y', color='k', width=1, length=0,
#                 direction='out')  # length=16,
ax1.set_ylabel('Intensity [Arb. Units]')
ax1.legend()

f.tight_layout()
f.subplots_adjust(wspace=0)

# if outName:
#     f.savefig(outName, bbox_inches='tight')

plt.show()

if __name__ == '__main__':
    main()

