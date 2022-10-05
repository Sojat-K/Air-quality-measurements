import mh_z19
from time import sleep

while(True):
	val=mh_z19.read()
	print(str(val))
	sleep(1)
