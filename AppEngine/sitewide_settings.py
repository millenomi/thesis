'''
Created on 19/dic/2009

@author: millenomi
'''

from os import environ

DEVELOPMENT_PREFIX = 'Development/'
DEBUG = ('SERVER_SOFTWARE' in environ and environ['SERVER_SOFTWARE'][0:len(DEVELOPMENT_PREFIX)] == DEVELOPMENT_PREFIX)

import logging
logging.warning('Sitewide settings reset: DEBUG = %s' % DEBUG)
if DEBUG:
	logging.getLogger().setLevel(logging.DEBUG)
	
OPEN_FOR_BUSINESS = False