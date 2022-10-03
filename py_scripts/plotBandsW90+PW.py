#! /usr/bin/python3
import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np
import plotBands as plPW
import plotBandsDosW90 as plW90

mpl.rcParams['lines.linewidth'] = 1

# first plot the bands from PW
fermi = 13.9718
rap, _ = plPW.readBandFile('GdN_B-S1.bands.rap')
dup = plPW.readBandFile('GdN_B-S1.bands') - fermi
ddw = plPW.readBandFile('GdN_B-S2.bands') - fermi
f, ax = plPW.plotBands('ΓXWKΓLUWLK|UX', rap, dup, ddw)

ax2 = ax.twiny()
# and add the bands from P90
plW90.plotBandsW90('GdN_W_up', 'GdN_W_dw', 13.9718, 'FCC', ylim=(-10, 10), ax=ax2, onlyBands=True)

for ln in ax2.lines:
    ln.set_color('k')

ax.set_zorder(ax2.get_zorder()+1)
ax.patch.set_visible(False)


ax.set_ylim(-4, 10)
ax2.set_xlim(0, 3.5383)
ax.set_xlim(0, 0.45216064305436676)

# f.set_figheight(6)
# f.set_figwidth(4)
f.savefig('GdN_W_PW+W90.pdf', bbox_inches='tight')

plt.show()
