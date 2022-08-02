import matplotlib as mpl
import numpy as np


class SquareRootScale(mpl.scale.ScaleBase):
    """
    ScaleBase class for generating square root scale.
    """

    name = 'squareroot'

    def __init__(self, axis, **kwargs):
        # note in older versions of matplotlib (<3.1), this worked fine.
        # mpl.scale.ScaleBase.__init__(self)

        # In newer versions (>=3.1), you also need to pass in `axis` as an arg
        mpl.scale.ScaleBase.__init__(self, axis)

    def set_default_locators_and_formatters(self, axis):
        axis.set_major_locator(mpl.ticker.AutoLocator())
        axis.set_major_formatter(mpl.ticker.ScalarFormatter())
        axis.set_minor_locator(mpl.ticker.NullLocator())
        axis.set_minor_formatter(mpl.ticker.NullFormatter())

    def limit_range_for_scale(self, vmin, vmax, minpos):
        return max(0., vmin), vmax

    class SquareRootTransform(mpl.transforms.Transform):
        input_dims = 1
        output_dims = 1
        is_separable = True

        def transform_non_affine(self, a):
            return np.array(a)**0.5

        def inverted(self):
            return SquareRootScale.InvertedSquareRootTransform()

    class InvertedSquareRootTransform(mpl.transforms.Transform):
        input_dims = 1
        output_dims = 1
        is_separable = True

        def transform(self, a):
            return np.array(a)**2

        def inverted(self):
            return SquareRootScale.SquareRootTransform()

    def get_transform(self):
        return self.SquareRootTransform()
