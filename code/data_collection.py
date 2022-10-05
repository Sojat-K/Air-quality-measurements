import mh_z19
import board
import digitalio
import adafruit_dht
import psutil
import json
import psutil
import asyncio
import os
from datetime import datetime, timezone
from azure.iot.device.aio import IoTHubDeviceClient
from time import sleep
from bmp280 import BMP280
from smbus import SMBus

# Init BMP280
bus = SMBus(1)
bmp280 = BMP280(i2c_dev=bus)

# Define VOC sensor settings
VOC_A = digitalio.DigitalInOut(board.D26)
VOC_B = digitalio.DigitalInOut(board.D19)
VOC_A.direction = digitalio.Direction.INPUT
VOC_B.direction = digitalio.Direction.INPUT

# 'Create'/configure the dht_11 sensor
dht_11 = adafruit_dht.DHT11(board.D17)

# Use global variable to update sleep time between measurements
# Currently measurement and post time is the same, could be developed further
# to support buffering measurements with smaller interval than posting
SLEEP_TIME = 5

# VOC level is read as two digit binary number, converting to decimal
# So:
# 00 -> 0
# 01 -> 1
# 10 -> 2
# 11 -> 3
def read_voc():
	total_value = 0
	aValue = VOC_A.value
	bValue = VOC_B.value
	if(aValue == 1):
		total_value+=2
	if(bValue == 1):
		total_value+=1
	return total_value

# Pull conn_str from env variable, which is the recommended way. This is set in a iaq.service -file, which loads this program on startup.
# There is a copy of it in this working directory, the one that is actually loaded is saved in path '/lib/systemd/system'
conn_str = os.getenv("IOTHUB_DEVICE_CONNECTION_STRING")

# Main loop and setting up for it
async def main():
	# Need to kill running libgpoiod process if there is one
	for process in psutil.process_iter():
		if process.name() == 'libgpoiod_pulsein' or process.name() == 'libgpiod_pulsei':
			process.kill()
	
	# Create the client object from connection string
	iot_device_client = IoTHubDeviceClient.create_from_connection_string(conn_str)

	# Connect the device
	await iot_device_client.connect()
	
	# Use global variable, so it can be updated by device twin
	global SLEEP_TIME

	# Function to handle twin changes
	# Currently only SLEEP_TIME is updated while running
	def twin_patch_handler(patch):
		try:
			global SLEEP_TIME
			SLEEP_TIME = patch['sleepTime']
		except:
			print("Failed to update sleepTime in twin_patch_handler")

	# Hookup the handler onto the client device
	iot_device_client.on_twin_desired_properties_patch_received = twin_patch_handler

	# Pull the twin on startup, to set the Id and SLEEP_TIME
	twin = await iot_device_client.get_twin()
	try:
		deviceId = twin['desired']['deviceId']
		SLEEP_TIME = twin['desired']['sleepTime']
	except:
		print("Failed to get Id from twin. Using 'unkown' as id")
		deviceId = "Unknown"

	# Main loop
	while(True):
		try:
			# Read values into a dictionary
			values=mh_z19.read()
			values['temp'] = dht_11.temperature
			values['humidity'] = dht_11.humidity
			values['voc'] = read_voc()
			values['pressure'] = bmp280.get_pressure()
			values['time'] = str(datetime.now(timezone.utc))
			values['metadata'] = {"evetType": "measurement"}
			values['deviceId'] = deviceId

			# Send the values to IoT Hub
			await iot_device_client.send_message(json.dumps(values))

		except RuntimeError as error:
			print(error.args[0]) # We can for the most part just eat these errors
			sleep(2)
			continue
		except Exception as error:
			# Shutdown on other errors
			await iot_device_client.shutdown()
			raise error
		sleep(SLEEP_TIME)

if __name__ == "__main__":
	asyncio.run(main())
