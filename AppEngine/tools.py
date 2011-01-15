import os

def path(*to):
	myself = os.path.realpath(__file__)
	return os.path.join(os.path.dirname(myself), *to)