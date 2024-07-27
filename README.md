# qBitRemote

A remote app for qBitTorrent webUI.
Available for Android, Linux, Windows and IOS (ipa file).

![photo_2024-07-27_17-46-39](https://github.com/user-attachments/assets/445b0e4e-2cc2-4a10-9fd9-768757cacafa)
![Screenshot_2024-07-27-17-49-20_1920x1080](https://github.com/user-attachments/assets/0996ee9b-8704-43bd-8df7-61755cd13bc9)


## Important Note
This app is not a standalone qBitTorrent client it manages your qBitTorrent webUI api. So you must already have a qBitTorrent client installed somewhere, enable the webUI for it and use this app to connect to it.

## Download
Head over to [releases](https://github.com/mirarr-app/qBitRemote/releases) and download it for your device.

## Built it yourself
First of all have [flutter]([https://docs.flutter.dev/get-started/install) version 3.22.3 installed and configured on your machine.

clone this repo and cd in it.
```bash
git clone https://github.com/mirarr-app/qBitRemote
cd qBitRemote
```

Run the following command to install the required dependencies:

```sh
flutter pub get
```

#### Build for Linux

To build the project for Linux, use the command:

```sh
flutter build linux
```

#### Build for Android (Debug)

To build the project for Android, use the command:

```sh
flutter build android
```

#### Build for Windows

To build the project for Windows, use the command:

```sh
flutter build windows
```

## Support
Consider starring the project.
[Consider Donating](https://github.com/mirarr-app/mirarr/blob/main/DONATION.md).
