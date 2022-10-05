from time import sleep
from datetime import datetime
import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BOARD)

signalA=35
signalB=37

GPIO.setup(signalA, GPIO.IN)
GPIO.setup(signalB, GPIO.IN)

while(True):
	aValue = GPIO.input(signalA)
	bValue = GPIO.input(signalB)
	print("aValue: " + str(aValue))
	print("bValue: " + str(bValue))
	if(aValue == 1 and bValue == 1):
		print(str(datetime.now()) + "VOC Level: Severe pollution")
	if(aValue == 0 and bValue == 1):
		print(str(datetime.now()) + "VOC level: Light pollution")
	if(aValue == 1 and bValue == 0):
		print(str(datetime.now()) + "VOC level: Moderate pollution")
	if(aValue == 0 and bValue == 0):
		print(str(datetime.now()) + "VOC level: Clean")
	sleep(1)
