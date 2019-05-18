# Android Bloatware Sanitizer
Tool that removes bloatware from Android devices.
This can also delete apps that can't be uninstalled through the app menu by the
user (Typically lists the option "Disable" insted of "Uninstall")


## Requirements:
- Linux OS
- adb must be installed (e.g. via Android Studio)


## Usage:
```
$ ./abs.sh --help
```


## Manpage:
```
Usage: abs.sh [OPTIONS]

Options are:
  --help:
    Prints this help menu

  --device <ID>:
    Device ID to be used - required if multple devices are connted.
    To retreive the device ID use 'adb devices'

  --list-categories
    Prints all available categories.

  --categories <LIST>:
    Categories to be included. Must be separated by commas. Optional.
    By default apps from all categories will be included.
    E.g. --categories google,shops

  --exclude-categories <LIST>:
    Categories to be excluded. Must be separated by commas. Optional.

  --skip-oem:
    If passed no OEM bloatware will be removed.
```
