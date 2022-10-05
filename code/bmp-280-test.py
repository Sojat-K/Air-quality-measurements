import time
from bmp280 import BMP280
from smbus import SMBus

# Init BMP280
bus = SMBus(1)
bmp280 = BMP280(i2c_dev=bus)

while True:
          pressure = bmp280.get_pressure()
          print(pressure)
          format_press = "{:.2f}".format(pressure)
          print('Pressure: ' + format_press + ' hPa \n')
          time.sleep(2)