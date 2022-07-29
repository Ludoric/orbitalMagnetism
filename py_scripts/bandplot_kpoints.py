#!/usr/bin/python3
import numpy as np
import sys


NAME_TO_CRYSTAL_KVEC = {  # in crystal coordinates
    'gamma': {'crystal': np.array((0.0,   0.0,   0.0  )),
                 'kvec': np.array((0.0,   0.0,   0.0  ))},
    'x':     {'crystal': np.array((0.0,   0.5,   0.5  )),
                 'kvec': np.array((0.0,   1.0,   0.0  ))},
    'l':     {'crystal': np.array((0.5,   0.5,   0.5  )),
                 'kvec': np.array((0.5,   0.5,   0.5  ))},
    'w':     {'crystal': np.array((0.25,  0.75,  0.5  )),
                 'kvec': np.array((0.5,   1.0,   0.0  ))},
    'u':     {'crystal': np.array((0.25,  0.625, 0.625)),
                 'kvec': np.array((0.25,  1.0,   0.25 ))},
    'k':     {'crystal': np.array((0.375, 0.75,  0.375)),
                 'kvec': np.array((0.75,  0.75,  0.0  ))},
}
KVEC_TO_NAME_CRYSTAL = {}
CRYSTAL_TO_NAME_KVEC = {}
for k, v in NAME_TO_CRYSTAL_KVEC.items():
    kvec = tuple(np.sort(v['kvec']))
    crystal = tuple(np.sort(v['crystal']))
    KVEC_TO_NAME_CRYSTAL[kvec] = {'name': k, 'crystal': v['crystal']}
    CRYSTAL_TO_NAME_KVEC[crystal] = {'name': k, 'kvec': v['kvec']}

def kvecFromName(s):
    if (key := s.lower()) in NAME_TO_CRYSTAL_KVEC:
        return NAME_TO_CRYSTAL_KVEC[key]['kvec']

def crystalFromName(s):
    if (key := s.lower()) in NAME_TO_CRYSTAL_KVEC:
        return NAME_TO_CRYSTAL_KVEC[key]['crystal']

def kvecFromCrystal(k):
    if (key := tuple(np.sort(np.abs(k)))) in CRYSTAL_TO_NAME_KVEC:
        return CRYSTAL_TO_NAME_KVEC[key]['kvec']

def crystalFromKvec(c):
    if (key := tuple(np.sort(np.abs(c)))) in KVEC_TO_NAME_CRYSTAL:
        return KVEC_TO_NAME_CRYSTAL[key]['crystal']

def nameFromCrystal(k):
    if (key := tuple(np.sort(np.abs(k)))) in CRYSTAL_TO_NAME_KVEC:
        return CRYSTAL_TO_NAME_KVEC[key]['name'].capitalize()

def nameFromKvec(c):
    if (key := tuple(np.sort(np.abs(c)))) in KVEC_TO_NAME_CRYSTAL:
        return KVEC_TO_NAME_CRYSTAL[key]['name'].capitalize()


def kpoints(NPts, route,):
    # or use 'crystal_b', and change α = NAME_TO_CRYSTAL_KVEC[a][0]
    output = ''
    dists = [np.linalg.norm(kvecFromName(a)-kvecFromName(b)) for a, b in zip(route, route[1:])]
    weight = NPts/sum(dists)
    dists.append(0)
    total = 0
    for a, d in zip(route, dists):
        α = kvecFromName(a)
        output += f'{α[0]:.3f} {α[1]:.3f} {α[2]:.3f} {d*weight: 4.0f}  ! {a}\n'
        total += int(f'{d*weight: 4.0f}')
    output = 'K_POINTS tpiba_b\n' + f'{len(route)}  ! total points = {total}\n' + output
    return(output)


if __name__ == '__main__':
    if len(sys.argv)==1:
        print('Script to generage k points for band plots using QUANTUM EXPRESSO')
        print('Usage:')
        print('\tbandplot_kpoints.py NUM_POINTS [L1, L2, ...]')
        print('\tWhere NUM_POINTS is an integer and L# are the labels of high symmetry points')
        print()
        exit()
    if sys.argv[1].isdigit():
        NPts = int(sys.argv[1])
    else:
        print('First argument must be an integer')
        exit()
    if len(sys.argv)==2:
        route = ['Gamma', 'X', 'W', 'K', 'Gamma', 'L', 'K', 'W', 'L', 'U', 'X', 'U', 'W']
        # route = ['Gamma', 'X', 'W', 'K', 'Gamma', 'L', 'U', 'W', 'L', 'K']  # ['U', 'X']
        # route = ['Gamma', 'X', 'W', 'L', 'Gamma', 'U', 'X', 'W']
    elif len(sys.argv)==3:
        print(f'Please supply two or more labels from {set(NAME_TO_CRYSTAL_KVEC)}')
        exit()
    else:
        route = sys.argv[2:]
        wrong = set(route) - set(NAME_TO_CRYSTAL_KVEC)
        if wrong:
            if len(wrong)==1:
                print(f'{str(wrong)[1:-1]} is not a valid point label.')
            else:
                print(f'{str(wrong)[1:-1]} are not valid point labels.')
            print(f'Try some of {set(NAME_TO_CRYSTAL_KVEC)} instead.')
            exit()

    print(kpoints(NPts, route))
