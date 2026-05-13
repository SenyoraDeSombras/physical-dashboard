import pynvml
import time
import serial
import math
import psutil
import serial.tools.list_ports
import logging
import os
import threading
from PIL import Image, ImageDraw
import pystray

# --- Configuration ---
UPDATE_INTERVAL = 0.1
LOG_FILE = os.path.join(os.path.dirname(__file__), "app_log.txt")

logging.basicConfig(
    level=logging.INFO,
    filename=LOG_FILE,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

class DashboardApp:
    def __init__(self):
        self.stop_event = threading.Event()
        self.icon = None
        self.device_thread = None

    def create_image(self):
        """Generates a simple icon image (a blue circle) if no icon file is provided."""
        width = 64
        height = 64
        image = Image.new('RGB', (width, height), color=(255, 255, 255))
        dc = ImageDraw.Draw(image)
        dc.ellipse((10, 10, 54, 54), fill=(0, 120, 215))
        return image

    def find_dashboard_device(self, baudrate=9600, target_query="Who A U?", expected_response="DASHBRD"):
        """Scans COM ports to find the specific device."""
        ports = serial.tools.list_ports.comports()
        if not ports:
            logging.warning("No COM ports detected.")
            return None

        logging.info(f"Found {len(ports)} potential ports. Scanning...")

        for port_info in ports:
            port_name = port_info.device
            try:
                with serial.Serial(port_name, baudrate, timeout=2) as ser:
                    time.sleep(0.1)
                    ser.reset_input_buffer()
                    ser.reset_output_buffer()
                    ser.write(target_query.encode('ascii'))
                    
                    response_raw = ser.readline()
                    if not response_raw:
                        continue

                    response_str = response_raw.decode('ascii', errors='ignore').strip()
                    if response_str == expected_response:
                        logging.info(f"SUCCESS: Device found on {port_name}!")
                        return port_name
            except Exception as e:
                logging.error(f"Error on {port_name}: {e}")
        
        return None

    def monitoring_loop(self):
        """The main logic running in a background thread."""
        logging.info("Monitoring thread started.")
        device = self.find_dashboard_device()
        
        if not device:
            logging.error("Could not locate dashboard. Thread exiting.")
            return

        try:
            pynvml.nvmlInit()
            with serial.Serial(device, 9600) as s:
                logging.info(f"Connected to {device}. Monitoring active...")
                handle = pynvml.nvmlDeviceGetHandleByIndex(0)

                while not self.stop_event.is_set():
                    # CPU Usage
                    cpu_util = psutil.cpu_percent(interval=None) # interval=None for non-blocking
                    
                    # GPU Usage
                    util = pynvml.nvmlDeviceGetUtilizationRates(handle)
                    mem = pynvml.nvmlDeviceGetMemoryInfo(handle)
                    
                    mem_norm = math.floor(100.0 * mem.used / mem.total)
                    gpu_util = round(util.gpu * 2.25)

                    # Send Data
                    try:
                        s.write(f"Set HIB: {mem_norm}\n".encode())
                        s.write(f"Set NDL: {gpu_util}\n".encode())
                        s.write(f"Set LOB: {cpu_util}\n".encode())
                    except serial.SerialException as e:
                        logging.error(f"Serial write error: {e}")
                        break

                    time.sleep(UPDATE_INTERVAL)
                    
        except Exception as e:
            logging.error(f"Critical error in monitoring loop: {e}")
        finally:
            logging.info("Monitoring thread cleaning up.")
            # Ensure pynvml is shut down if possible
            try:
                pynvml.nvmlShutdown()
            except:
                pass

    def on_exit(self, icon, item):
        """Callback for the 'Exit' menu item."""
        logging.info("Exit requested via Tray.")
        self.stop_event.set()
        icon.stop()

    def run(self):
        """Starts the monitoring thread and the tray icon."""
        # 1. Start the monitoring logic in the background
        self.device_thread = threading.Thread(target=self.monitoring_loop, daemon=True)
        self.device_thread.start()

        # 2. Setup the System Tray Icon
        menu = pystray.Menu(
            pystray.MenuItem("Exit", self.on_exit)
        )
        
        self.icon = pystray.Icon(
            "DashboardMonitor",
            self.create_image(),
            "Dashboard Monitor Active",
            menu
        )

        # 3. Run the icon loop (this blocks the main thread)
        self.icon.run()

        # 4. Wait for the background thread to finish cleaning up
        if self.device_thread:
            self.device_thread.join(timeout=2)
        logging.info("Application exited cleanly.")

if __name__ == "__main__":
    app = DashboardApp()
    app.run()
