#!/usr/bin/env python
# A quick and dirty regexp replacement filter

import re

def re_sub(s, p, r):
    return re.sub(p, r, s)

class FilterModule(object):
    '''
    custom jinja2 filter for regexp substitution
    '''

    def filters(self):
        return {
            're_sub': re_sub
        }
