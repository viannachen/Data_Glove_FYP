import os, sys
import asyncio
import platform
from datetime import datetime
from typing import Callable, Any

from aioconsole import ainput
from bleak import BleakClient, discover

root_path = os.environ["HOME"]
output_file = f"{root_path}/Desktop/inputdata.csv"

read_characteristic = "00001143-0000-1000-8000-00805f9b34fb"
write_characteristic = "00001142-0000-1000-8000-00805f9b34fb"


class Connection:
    
    client: BleakClient = None
    
    def __init__(
        self,
        loop: asyncio.AbstractEventLoop,
        read_characteristic: str,
        write_characteristic: str,
        data_dump_handler: Callable[[str, Any], None],
        data_dump_size: int = 5,
    ):
        self.loop = loop
        self.read_characteristic = read_characteristic
        self.write_characteristic = write_characteristic
        self.data_dump_handler = data_dump_handler
        self.data_dump_size = data_dump_size

        # Device state
        self.connected = False
        self.connected_device = None

        # RX Buffer
        self.last_packet_time = datetime.now()
        self.rx_data = []
        self.rx_timestamps = []
        self.rx_delays = []

    def on_disconnect(self, client: BleakClient):
        self.connected = False
        # Put code here to handle what happens on disconnet.
        print(f"Disconnected from {self.connected_device.name}!")

    def notification_handler(self, sender: str, data: Any):
        self.rx_data.append(int.from_bytes(data, byteorder="big"))
        if len(self.rx_data) >= self.data_dump_size:
            self.data_dump_handler(self.rx_data)
            self.clear_lists()

    async def manager(self):
        print("Starting connection manager.")
        while True:
            if self.client:
                await self.connect()
            else:
                await self.select_device()
                await asyncio.sleep(15.0, loop=loop)
    
    async def connect(self):
        if self.connected:
            return
        try:
            await self.client.connect()
            self.connected = await self.client.is_connected()
            if self.connected:
                print(f"Connected to {self.connected_device.name}")
                self.client.set_disconnected_callback(self.on_disconnect)
                await self.client.start_notify(
                    self.read_characteristic, self.notification_handler,
                )
                while True:
                    if not self.connected:
                        break
                    await asyncio.sleep(5.0, loop=loop)
            else:
                print(f"Failed to connect to {self.connected_device.name}")
        except Exception as e:
            print(e)

    async def cleanup(self):
        if self.client:
            await self.client.stop_notify(read_characteristic)
            await self.client.disconnect()

    async def select_device(self):
        print("Bluetooh LE hardware warming up...")
        await asyncio.sleep(2.0, loop=loop) # Wait for BLE to initialize.
        devices = await discover()

        print("Please select device: ")
        for i, device in enumerate(devices):
            print(f"{i}: {device.name}")

        response = -1
        while True:
            response = await ainput("Select device: ")
            try:
                response = int(response.strip())
            except:
                print("Please make valid selection.")
            
            if response > -1 and response < len(devices):
                break
            else:
                print("Please make valid selection.")

        print(f"Connecting to {devices[response].name}")
        self.connected_device = devices[response]
        self.client = BleakClient(devices[response].address, loop=self.loop)
    
    def clear_lists(self):
        self.rx_data.clear()


class DataToFile:

    column_names = ["thumb", "index_MCP", "middle_MCP", "index_PIP", "middle_PIP"]

    def __init__(self, write_path):
        self.path = write_path

    def write_to_csv(self, data_values):

        with open(self.path, "a+") as f:
            if os.stat(self.path).st_size == 0:
                print("Created file.")
                f.write(",".join([str(name) for name in self.column_names]) + "\n")
            else:
                for i in range(len(data_values)):
                    if i % 5 == 4:
                        f.write(f"{data_values[i]} \n")
                    else:
                        f.write(f"{data_values[i]},")
                # f.write(f"{data_values[i]}," if i % 5 != 0 else "\n" for i in range(len(data_values)))

if __name__ == "__main__":
    # Create the event loop.
    loop = asyncio.get_event_loop()

    data_to_file = DataToFile(output_file)
    connection = Connection(
        loop, read_characteristic, write_characteristic, data_to_file.write_to_csv
    )
    try:
        asyncio.ensure_future(connection.manager())
        loop.run_forever()
    except KeyboardInterrupt:
        print()
        print("User stopped program.")
    finally:
        print("Disconnecting...")
        loop.run_until_complete(connection.cleanup())
