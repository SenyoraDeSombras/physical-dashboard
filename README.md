# Physical PC Telemetry Dashboard

![License](https://img.shields.io/badge/license-GPL3-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)
![Hardware](https://img.shields.io/badge/hardware-ESP32-orange)

A real-time, physical hardware monitoring system that bridges PC performance metrics (CPU, GPU, and VRAM) to a custom-built desktop dashboard. The system utilizes an ESP32 microcontroller to drive a magnetoelectric galvanometer (analog needle) and a 4-digit 7-segment display.

## 🚀 Features

- **Real-time Monitoring**: Low-latency tracking of CPU utilization, GPU utilization, and VRAM usage.
- **Hybrid Display**: 
    - **Analog**: A galvanometer needle driven via PWM for intuitive, "analog-feel" GPU monitoring.
    - **Digital**: A 4-digit 7-segment display providing precise numerical data for CPU and VRAM.
- **Auto-Discovery**: The Python backend automatically scans COM ports to detect and handshake with the ESP32 hardware.
- **System Tray Integration**: Runs as a lightweight background process with a system tray icon for easy control.
- **Robust Communication**: Custom serial protocol with command validation and error handling.

## 🛠 Hardware Requirements

| Component | Specification | Description |
| :--- | :--- | :--- |
| **Microcontroller** | ESP32 | Main logic and PWM/Serial controller |
| **Display** | TM1637 4-Digit 7-Segment | Digital readout for CPU/VRAM |
| **Actuator** | Magnetoelectric Galvanometer | Analog needle movement |

### Pin Mapping (ESP32)
- **PWM Output (Needle)**: GPIO 14
- **TM1637 CLK**: GPIO 8
- **TM1637 DIO**: GPIO 9
### 🔌Schematic
![Schematic](https://github.com/SenyoraDeSombras/physical-dashboard/blob/main/schematics.png) "Schematic")
## 💻 Software Requirements

### Backend (Python 3.x)
- `pynvml`: NVIDIA Management Library interface.
- `psutil`: System and process utilities.
- `pyserial`: Serial communication.
- `pystray`: System tray icon integration.
- `Pillow`: Image processing for the tray icon.

### Firmware (Arduino/C++)
- `TM1637Display` library.
- ESP32 Board Support Package.

## ⚙️ Installation & Setup

### 1. Hardware Flashing
1. Open the `dashboard.ino` file in the Arduino IDE.
2. Select your ESP32 board model.
3. Connect your ESP32 via USB.
4. Click **Upload**.

### 2. Software Environment Setup
Clone this repository and install the required Python dependencies:

```bash
# Clone the repository
git clone https://github.com/SenyoraDeSombras/physical-dashboard.git
cd physical-dashboard

# Install dependencies
pip install pynvml psutil pyserial pystray Pillow
```

### 3. Running the Dashboard
Ensure your ESP32 is plugged into your PC, then run:

```bash
python dashboard_app.pyw
```

The application will scan your COM ports, perform a handshake (`Who A U?` $\rightarrow$ `DASHBRD`), and begin updating the hardware.

## 📐 System Architecture

### Communication Protocol
The system uses a text-based serial protocol for simplicity and reliability:

| Command | Target | Description |
| :--- | :--- | :--- |
| `Who A U?` | ESP32 | Handshake request from PC to verify device presence. |
| `Set NDL: <val>` | Galvanometer | Sets PWM duty cycle (0-225) for the needle. |
| `Set HIB: <val>` | 7-Seg (High) | Sets the first two digits of the 4-digit display. |
| `Set LOB: <val>` | 7-Seg (Low) | Sets the last two digits of the 4-digit display. |

### Data Flow
1. **Python Service** polls `psutil` (CPU) and `NVML` (GPU/VRAM).
2. **Data Processing**: GPU utilization is scaled for the analog needle movement.
3. **Serial Transmission**: Commands are sent over USB-Serial.
4. **ESP32 Parsing**: The firmware parses the string, validates the range, and updates the hardware registers.

## 🛡 Safety & Validation
- **Embedded Validation**: The ESP32 firmware performs bounds-checking on all incoming serial data to prevent invalid PWM duty cycles or display errors.
- **Timeout Protection**: The Python script includes a 2-second timeout during the device discovery phase to prevent blocking.

## 📝 License
Distributed under the GPL3 License. See `LICENSE` for more information.

---
**Author:** SenyoraDeSombras
**Project Role:** Lead Hardware/Software Engineer
