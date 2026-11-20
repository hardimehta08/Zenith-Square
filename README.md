# Zenith Square

This guide explains how to set up and run Zenith Square on Windows. It is written for teammates who are setting it up for the first time.

## What runs where?

When you test with a phone and the database is on your laptop:

| Part | Where it runs |
| --- | --- |
| Flutter app | Your Android phone |
| Django API | Your laptop |
| PostgreSQL database | Your laptop |

The phone talks to Django over Wi-Fi. Django talks to PostgreSQL on the laptop. **Do not connect the phone directly to PostgreSQL or open PostgreSQL port `5432` to Wi-Fi.**

If the app is already installed on your phone, you can unplug the USB cable and open the app normally. Keep the laptop on and the Django server running if you want the app to show live data from the laptop.

## What you need

- Windows 10 or 11
- Python 3.11.4
- PostgreSQL 18.6 or a compatible version
- Flutter 3.41.6 (includes Dart 3.11.4)
- Android Studio and Android SDK Platform Tools if you are testing on Android
- This project downloaded to your laptop

## Part 1: Create the database

1. Open **pgAdmin** and connect to your PostgreSQL server.
2. In the left panel, expand **Servers** and your PostgreSQL server.
3. Right-click **Databases**, choose **Create → Database**.
4. Enter a database name (for example, `zenith_square`) and click **Save**.
5. Remember the database name and the PostgreSQL username and password. You will need them in the next part.

## Part 2: Configure the project

1. Open the project folder named `Zenith-Square` in VS Code.
2. In the project root (the same folder as this README), create a file named `.env`.
3. Add the following lines, replacing the example values with your own:

   ```text
   DB_NAME=zenith_square
   DB_USER=your_postgres_username
   DB_PASSWORD=your_postgres_password
   DB_HOST=localhost
   DB_PORT=5432
   DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
   ```

   The `.env` file contains your database password. It is ignored by Git; **do not share it or commit it to the repository**.

## Part 3: Set up Django

1. In VS Code, choose **Terminal → New Terminal**. Make sure the terminal is at the `Zenith-Square` project root.
2. Create a Python virtual environment and install the project packages:

   ```powershell
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   python -m pip install -r requirements.txt
   ```

   If PowerShell says it cannot run `Activate.ps1`, open **Command Prompt** in the project root and run:

   ```cmd
   .venv\Scripts\activate.bat
   ```

   Continue with the remaining Python commands in that same Command Prompt window so the virtual environment stays active.

3. In the same terminal, move into the backend folder and create the database tables:

   ```powershell
   Set-Location backend
   python manage.py migrate
   ```

## Part 4: Start the app on your laptop

### Start the Django API

The terminal from Part 3 should already be in the `backend` folder. Keep it open and start Django:

```powershell
python manage.py runserver 127.0.0.1:8000
```

### Start the Flutter app

Open a second VS Code terminal. From the project root, run:

```powershell
Set-Location frontend
flutter pub get
flutter run
```

Flutter will run the app on the available device you select (for example, an emulator or a connected phone).

## Part 5: Use the app on a real phone over Wi-Fi

You do this setup when Django and PostgreSQL are on your laptop and the app is on your phone.

### A. Connect the phone to Django

1. Connect the phone and laptop to the **same trusted Wi-Fi network**. Guest networks may prevent devices from talking to each other.
2. On the laptop, open PowerShell and run:

   ```powershell
   ipconfig
   ```

3. Find **IPv4 Address** under the active **Wi-Fi** adapter. Use that address in the steps below. For example, it might be `192.168.1.8`. Do not use an address belonging to a VPN or virtual network adapter.
4. Open the `.env` file in the project root. Add the laptop's Wi-Fi address to `DJANGO_ALLOWED_HOSTS`. For example:

   ```text
   DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,192.168.1.8
   ```

   Replace `192.168.1.8` with the address you found. Save the file.
5. Stop Django if it is already running (press **Ctrl+C** in its terminal). In the `backend` folder, start it so other devices on your Wi-Fi can reach it:

   ```powershell
   python manage.py runserver 0.0.0.0:8000
   ```

6. If Windows Firewall asks whether Python can use the network, allow it on **Private networks only**. If the phone still cannot connect, a Windows administrator can add a rule:

   - Open Start and search for **Windows Defender Firewall with Advanced Security**.
   - Select **Inbound Rules → New Rule**.
   - Choose **Port**, select **TCP**, and enter `8000` as the local port.
   - Choose **Allow the connection**, select **Private** only, and give the rule a name such as `Zenith Square Django`.

   Do not open port `5432`.
7. On the phone, open Chrome and visit `http://192.168.1.8:8000/api/societies/`, replacing the example address with the laptop's address. If the API responds, the phone can reach Django.

### B. Run or install the Flutter app without a USB cable

Wireless debugging works on Android 11 and newer. Your phone and laptop must remain on the same Wi-Fi network.

1. On the phone, open **Settings → About phone → Software information** and tap **Build number** seven times. This enables Developer options. (The menu names may differ slightly by phone.)
2. Open **Settings → Developer options → Wireless debugging** and turn it on.
3. Tap **Pair device with pairing code**. Keep the code on the phone screen.
4. In PowerShell on the laptop, run the command below using the phone's IP address and **pairing port** shown in that dialog. When asked, enter the pairing code:

   ```powershell
   adb pair PHONE_IP:PAIRING_PORT
   ```

5. Return to the main **Wireless debugging** screen on the phone. Note its IP address and **device port**. If the phone does not appear automatically, connect to it:

   ```powershell
   adb connect PHONE_IP:DEVICE_PORT
   flutter devices
   ```

   `flutter devices` lists connected devices. Copy the phone's device ID from that list.
6. Open a new PowerShell terminal at the project root, go to the `frontend` folder, and run the app. Replace `PHONE_DEVICE_ID` with the ID from the previous step, and replace `192.168.1.8` with your laptop's Wi-Fi address:

   ```powershell
   Set-Location frontend
   flutter run -d PHONE_DEVICE_ID --dart-define=API_BASE_URL=http://192.168.1.8:8000/api
   ```

Flutter installs and launches the app over Wi-Fi. After it is installed, you can disconnect from the Flutter session and open the app from the phone's app list. The laptop's Django server must still be running for live data.

If PowerShell says `adb` is not recognized, use `adb.exe` from your Android SDK's `platform-tools` folder or add that folder to your Windows `PATH`.

### If the laptop's Wi-Fi address changes

The address may change when you reconnect to Wi-Fi. If that happens:

1. Find the new Wi-Fi IPv4 address with `ipconfig`.
2. Update `DJANGO_ALLOWED_HOSTS` in `.env`.
3. Restart Django.
4. Run or rebuild the app with the new address in `API_BASE_URL`.

## Common problems

### The phone cannot open the API address

- Check that the phone and laptop are on the same Wi-Fi.
- Check that Django is running with `0.0.0.0:8000`, not just `127.0.0.1:8000`.
- Check the laptop's current Wi-Fi IPv4 address and the `DJANGO_ALLOWED_HOSTS` value.
- Check that Windows Firewall allows Python/Django on the **Private** network.

### The app opens but cannot load data

- The laptop and Django server must stay on.
- Check that the app was run or built with `API_BASE_URL` set to the laptop's current address, ending in `/api`.
- Open `http://LAPTOP_IP:8000/api/societies/` in the phone browser to test the connection.

### The app stops showing live data when I leave home

The laptop-hosted API is only reachable on the same local network. To use the app from another network, the API and database need to be deployed to a server reachable over the internet, and the app should use that server's HTTPS address.

## Keep the development server safe

The Django development server and the local `http://` address are for testing on a trusted private network only. Do not use them on public Wi-Fi or as a production deployment. Keep PostgreSQL on the laptop and do not expose port `5432`.

## Stop the development setup

- In the Django terminal, press **Ctrl+C** to stop the server.
- In the laptop terminal, stop Android Debug Bridge and any phone connection:

  ```powershell
  adb disconnect
  adb kill-server
  ```

- Remove the temporary Windows Firewall rule for port `8000` if you created one and no longer need it:
  1. Open **Windows Defender Firewall with Advanced Security**.
  2. Select **Inbound Rules**.
  3. Find the rule named `Zenith Square Django`, right-click it, and choose **Delete**.
- On the phone, close the temporary development connections:
  1. Turn off **Settings → Developer options → Wireless debugging**.
  2. Turn off **USB debugging** if it is no longer needed.
  3. Open **Settings → Developer options → Revoke USB debugging authorizations** to remove previously approved computers.
  4. Turn the **Developer options** switch off if you do not need it for development.
- If you added a laptop Wi-Fi address to `DJANGO_ALLOWED_HOSTS`, remove it and keep only trusted values such as `localhost,127.0.0.1`:

  ```text
  DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
  ```

  Restart Django before using the setup again.
- In the virtual-environment terminal, run:

  ```powershell
  deactivate
  ```

## Future safety checklist

Use this checklist when the setup is not actively being developed.

### On the phone

- Turn off **Wireless debugging** and **USB debugging**.
- Revoke USB debugging authorizations for old or unused computers.
- Turn off Developer options when no longer needed.
- Sign out of or remove any phone profile that should not remain on the device.
- Do not save the laptop's private Wi-Fi address or pairing code in public notes or screenshots.
- Do not install APKs or accept debugging prompts from unknown computers.
- Keep Bluetooth, location, nearby-device sharing, and public Wi-Fi sharing off unless needed. Do not expose the app on public or guest Wi-Fi.

### On the laptop

- Stop the Django server with **Ctrl+C**.
- Run `adb disconnect` and `adb kill-server` when Android debugging is finished.
- Remove or disable the `Zenith Square Django` firewall rule for port `8000` unless it is actively needed.
- Keep the PostgreSQL service, port `5432`, `pgAdmin`, and database credentials private. Do not open port `5432` in Windows Firewall or on the router.
- Remove temporary laptop IP addresses from `DJANGO_ALLOWED_HOSTS` when the address is no longer used.
- Keep `.env` private, never commit it or send it in chat, and rotate the database or application secrets if it is accidentally shared.
- Use **Private** network mode only for the trusted test network, and use **Public** network mode in unfamiliar places.
- Turn off Windows **Developer Mode** if it was enabled only for development:
  **Settings → System → For developers → Developer Mode**.
- Remove old VS Code port forwards, SSH tunnels, remote-debug sessions, or virtual-network adapters when not in use.
- Lock the laptop and avoid leaving VS Code, `pgAdmin`, Django terminals, or the project open in shared locations.

### Developer-options items to keep disabled

On Android, leave these off unless a specific development step requires them:

- **Wireless debugging**
- **USB debugging**
- **Wireless display** or media casting
- **Debug app** / chosen debug application
- **Stay awake** while charging
- **Mock location** or fake location apps
- **Force 4x MSAA** and unnecessary graphics or performance profiling tools
- **Disable/force desktop mode**, free-form windows, and other experimental visual options
- **Enable/disable Bluetooth HCI snoop log**, USB configuration, or other logging options after debugging finishes

On Windows, leave these options off unless they are needed:

- **Developer Mode**, if enabled temporarily
- **Remote debugging** and remote desktop access
- Any old or temporary **ADB**, firewall, SSH, port-forwarding, or remote-access rules
