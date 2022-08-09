#!/usr/bin/python3
import numpy as np
import plotly.graph_objects as go
from scipy.spatial import Voronoi
import bandplot_kpoints as KPts


def main():
    # 'lattice_vectors' defines the unit cell of a primitive lattice
    # remember that a real space fcc lattice is a reciprocal space bcc lattice!
    lattice_vectors = EXAMPLE_LATTICES['BCC']

    # the basis for hcp crystal lattice
    # basis = [np.array([1/3, 2/3, 1/4]), np.array([2/3, 1/3, 3/4])]
    # the basis for a primitive lattice
    basis = [np.array([0, 0, 0])]

    # Compute Voronoi diagram from lattice points
    voronoi = Voronoi(generateLattice(lattice_vectors, basis))

    fig = go.Figure()
    addLatticePointsToPlot(fig, voronoi)
    addPrimitiveCellToPlot(fig, lattice_vectors)
    addVoronoiCellToPlot(fig, voronoi)
    plotCriticalPoints(fig, 'FCC')

    fig.update_layout(scene=dict(
        xaxis=dict(showticklabels=False, showgrid=False, showbackground=True),
        yaxis=dict(showticklabels=False, showgrid=False, showbackground=True),
        zaxis=dict(showticklabels=False, showgrid=False, showbackground=True),
        ))
    fig.show()


EXAMPLE_LATTICES = {
    'CUB': np.array([np.array([1, 0, 0]),
                    np.array([0, 1, 0]),
                    np.array([0, 0, 1])]),
    'BCC': np.array([np.array([-1, 1, 1]),
                     np.array([1, -1, 1]),
                     np.array([1, 1, -1])]),
    'FCC': np.array([np.array([0, 1, 1]),
                     np.array([1, 0, 1]),
                     np.array([1, 1, 0])]),
    'HCP': {
        'real': np.array([0.5*np.array([1, np.sqrt(3), 0]),
                          0.5*np.array([1, -np.sqrt(3), 0]),
                          1.0*np.array([0, 0, np.sqrt(8/3)])]),
        'reciprocal': np.array([np.array([-1, -1/np.sqrt(3), 0]),
                                np.array([-1, 1/np.sqrt(3), 0]),
                                np.array([0, 0, -np.sqrt(6)/4])])
    }
}


def generateLattice(
        lattice_vectors, basis=[np.array([0, 0, 0])], LATTICE_RADIUS=1):
    # generate enough lattice points to completely define the Voronoi cell
    lattice = []
    for i in range(int(-LATTICE_RADIUS), int(LATTICE_RADIUS)+1):
        for j in range(int(-LATTICE_RADIUS), int(LATTICE_RADIUS)+1):
            for k in range(int(-LATTICE_RADIUS), int(LATTICE_RADIUS)+1):
                for b in basis:
                    lattice.append((b + np.array([i, j, k]))@lattice_vectors)
    return lattice


def addPrimitiveCellToPlot(fig, lattice_vectors):
    # draw the primitive cell:
    path = ((0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0), (0, 0, 0),
            (1, 0, 0), (1, 0, 1), (0, 0, 1), (1, 0, 1),
            (1, 1, 1), (0, 1, 1), (1, 1, 1),
            (1, 1, 0), (0, 1, 0), (1, 1, 0),
            (1, 0, 0))
    path = np.array([np.array(p) for p in path])  # - (0.5, 0.5, 0.5)
    x, y, z = (path@lattice_vectors).T
    fig.add_trace(go.Scatter3d(
        x=x, y=y, z=z, name='Primitive Cell',
        mode='lines', line={'color': 'black'}
    ))


def addLatticePointsToPlot(fig, voronoi):
    # draw the lattice points:
    x, y, z = voronoi.points.T
    fig.add_trace(go.Scatter3d(
        x=x, y=y, z=z, name='Lattice Points',
        mode='markers', marker={'color': 'black'}
    ))


def addVoronoiCellToPlot(fig, voronoi):
    """
    We only want to draw one complete Voronoi cell (they are all the same)

    Finding the region (volume) with the most vertecies should guarentee this
    Thus 'largest' is the Voronoi cell we have chosen to draw
    """
    largest = sorted([(len(v), v) for v in voronoi.regions])[-1][1]

    # want to draw a volume, so need triangles for the faces
    Voronoi_ijks = []
    Voronoi_edges = []  # also want to highlight edges in red
    for v in voronoi.ridge_vertices:  # for every face
        # is this face part of our chosen Voronoi cell
        if all([w in largest for w in v]):
            # turn the polygonal face into triangles so we can draw it
            Voronoi_ijks += [(v[0], v[i-1], v[i]) for i in range(2, len(v))]

            # Also want to draw the edges of the face
            edges = [voronoi.vertices[i] for i in v]
            edges.append(edges[0])  # make it a closed loop
            edges.append((np.nan, np.nan, np.nan))  # don't connect face loops
            Voronoi_edges += edges
    x, y, z = np.array(Voronoi_edges).T
    fig.add_trace(go.Scatter3d(
        x=x, y=y, z=z, name='Cell Edges',
        connectgaps=False, mode='lines', line={'color': 'blue'}
    ))

    # draw the cell faces
    # i, j, k = list(map(list, zip(*Voronoi_ijks)))  # transpose
    i, j, k = np.array(Voronoi_ijks).T
    x, y, z = voronoi.vertices.T
    fig.add_trace(go.Mesh3d(
        x=x, y=y, z=z, i=i, j=j, k=k, name='Cell Faces',
        showlegend=True, flatshading=True, color='red', opacity=0.4))


def plotCriticalPoints(fig, cell='FCC', route=None):
    if cell not in KPts.getCells():
        print(f'{cell} is not a known cell.\nTry one of: {KPts.getCells()}')
        return
    if not route:
        route = KPts.getRecommendedRoute(cell)
    if (extraPts := set(route) - (KPts.getPoints(cell) | {'|', })):
        print(f'{extraPts} are not known points for a {cell} cell.')
        print(f'\tTry some of: {KPts.getPoints(cell)} instead')
        # return
    cleanRoute = route.translate({ord(x): None for x in extraPts})
    # label a unique set of lattice points
    unique = ''.join(set(cleanRoute.replace('|', '')))
    x, y, z = np.array([KPts.kvecFromName(s, cell) for s in unique]).T
    fig.add_trace(go.Scatter3d(
        x=x, y=y, z=z, name='Critical Points',
        mode='markers+text', marker={'color': 'green'}, text=list(unique),
        textfont={'color': 'green', 'size': 18}, textposition='top center'
    ))
    # plot the lines between k points
    # + jank to ensure that disjoint lines are delt with properly
    x, y, z = np.array([
        (np.nan, np.nan, np.nan) if (x := KPts.kvecFromName(s, cell)) is None
        else x for s in cleanRoute]).T
    fig.add_trace(go.Scatter3d(
        x=x, y=y, z=z, name='Critical Lines',
        mode='lines', line={'color': 'green'}
    ))


if __name__ == '__main__':
    main()
