from __future__ import absolute_import, print_function, unicode_literals
from builtins import dict, str

from util import _KappaClientTest, BIN_DIR, run_nose

import kappy


class StdClientTest(_KappaClientTest):
    """ Integration test for kappa client"""

    def getRuntime(self, project_id):
        return kappy.KappaStd(BIN_DIR)


if __name__ == '__main__':
    run_nose(__file__)