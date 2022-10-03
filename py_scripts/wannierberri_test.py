import wannierberri as wberri
import numpy as np

system=wberri.System_w90('GdN_W_up', berry=True)

generators = ['Inversion','C4z','TimeReversal*C2x'] # these are the wrong symmertries
system.set_symmetry(generators)
grid = wberri.Grid(system,length=200)

parallel=wberri.Parallel(num_cpus=64)

wberri.integrate(system, grid,
            Efermi=np.linspace(12.,13.,1001),
            smearEf=10, # 10K
            quantities=['ahc', 'dos', 'cumdos'],
            parallel=parallel,
            adpt_num_iter=10,
            fout_name='GdN_W_up')

