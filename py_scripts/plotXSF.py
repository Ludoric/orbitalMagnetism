#! /usr/bin/python3
import matplotlib.pyplot as plt
import numpy as np
n = lambda v: v if (l:=np.sum(np.abs(v)**2)**0.5) == 0 else v/l 

def main():
    # want to sample along the (-1 0 -1) axis at -5Á 
    xsfdat = readXSF('GdN_W_up_00007.xsf')

    g = xsfdat['3DField'][0]
    ax = np.linalg.inv(g['axes'].T)
    origin = g['origin']
    # so a sensable direction in a fcc lattice is  (1 0 0)
    m_conventional = np.array((1, 0, 0))
    m_prim = ax@m_conventional
    print(m_prim)

    dimx, dimy = 200, 200
    xy = np.mgrid[1.0:1.0:1j, -1:1:dimx*1j, -1:1:dimy*1j]
    pts = (ax@xy.reshape((3, -1))).T # origin
    field = g['field'][..., np.newaxis]
    δf = np.linalg.norm(ax, axis=1)/field.shape[:-1]
    print(np.linalg.norm(ax, axis=1))
    cols = lerp3d(field, δf, pts, outliers='map').reshape((dimx, dimy))
    
    m = np.max(np.abs(cols))
    plt.imshow(cols, cmap='seismic', vmin=-m, vmax=m, origin='lower')
    plt.show()
    

def readXSF(fname):
    def dataGrid3d(f, info):
        gridtype=f.readline()
        if gridtype.strip() != '3D_field':
            print('Grid is of unknown type! It\'s', gridtype)
        grids = []
        while 'BEGIN_DATAGRID_3D' in f.readline():
            gdims = np.array(f.readline().split(), dtype=int)
            start = np.array(f.readline().split(), dtype=float)
            axes = np.array([f.readline().split() for _ in range(3)], dtype=float)
            pts = []
            while len(pts) < gdims.prod():
                pts.extend(f.readline().split())
            field = np.array(pts, dtype=float).reshape(gdims, order='F')
            grids.append({'origin': start, 'axes':axes, 'field': field})
            # field in fortran order
        info['3DField'] = grids
            
    info = {'fname': fname}
    with open(fname, 'r') as f:
        while ln:=f.readline():
            print(ln.strip())
            match ln.strip():
                # case 'CRYSTAL':
                #     # do nothing; deal with the other cases as they come
                case 'PRIMVEC':
                    info['PRIMVEC'] = np.array(
                        [f.readline().split() for _ in range(3)], dtype=float)
                case 'CONVVEC':
                    info['CONVVEC'] = np.array(
                            [f.readline().split() for _ in range(3)], dtype=float)
                case 'PRIMCOORD':
                    # second digit is always 1 (for primcoord)
                    nprim = int(f.readline().split()[0])
                    primcoords = []
                    for _ in range(nprim):
                        ln = f.readline().split()
                        primcoords.append((ln[0], np.array(ln[1:], dtype=float)))
                    info['PRIMCOORD'] = primcoords
                case 'BEGIN_BLOCK_DATAGRID_3D':
                    dataGrid3d(f, info)
                # case _:
                #     # it's a comment or a blank line
    print(ln.strip())
    return info


def lerp3d(F, δF, p, *, outliers=np.nan):
    """
        Linearly interpolatate values for points on a 3d grid
        F  [A×B×C×3] - vector field
        δF [3]       - distance between points on the grid along each axis
        p  [M×3]     - position within the grid

        returns v [M×3], the interpolated values of F at p

        This function does not assume the grid is square, or that the
            scale is equal in each direction

        I wrote this function in C first, then copied it accross to python
    """
    if outliers == 'map' or isinstance(outliers, float):
        # basically assume it's map
        p = p % (δF*F.shape[:-1])  # MAP points onto the grid
    elif outliers == 'move':
        p %= (δF*F.shape[:-1])   # MOVE points onto the grid
    else:
        print('I don\' know what to do with outliers!')
        return

    low_index = (p/δF).astype(int)
    idx = np.concatenate((low_index, (low_index+1) % F.shape[:-1]), axis=-1).T
    high_factor = p/δF - low_index
    ftr = np.concatenate((1.0-high_factor, high_factor), axis=-1).T[..., None]
    # there may be better ways of doing this in python...?
    v = F[idx[0], idx[1], idx[2]] * (ftr[0]*ftr[1]*ftr[2])
    v += F[idx[0], idx[1], idx[5]] * (ftr[0]*ftr[1]*ftr[5])
    v += F[idx[0], idx[4], idx[2]] * (ftr[0]*ftr[4]*ftr[2])
    v += F[idx[0], idx[4], idx[5]] * (ftr[0]*ftr[4]*ftr[5])
    v += F[idx[3], idx[1], idx[2]] * (ftr[3]*ftr[1]*ftr[2])
    v += F[idx[3], idx[1], idx[5]] * (ftr[3]*ftr[1]*ftr[5])
    v += F[idx[3], idx[4], idx[2]] * (ftr[3]*ftr[4]*ftr[2])
    v += F[idx[3], idx[4], idx[5]] * (ftr[3]*ftr[4]*ftr[5])
    if isinstance(outliers, float):
        v[np.any((0 > p) | (p > δF*F.shape[:-1]), 1, keepdims=True)] = outliers
    return v


if __name__ == '__main__':
    main()
