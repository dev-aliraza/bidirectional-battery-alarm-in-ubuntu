# Bi-directional Battery Alarm in Ubuntu
Ubuntu will generate an alert when battery power will reach described high or low percentage. This script will continously monitor your battery percentage

### Required Ubuntu Packages
* sox
* acpi or upower

Run Following commands to install the packages
```
sudo apt install sox
sudo apt install acpi
```
If `acpi` package is not available, install `upower` package
```
sudo apt install upower
```

### How to Run?
```
/bin/bash {Directory}/batteryAlert.sh both
```
This command will run script with default values that is 20% for low battery alert and 95% for high battery alert

```
/bin/bash {Directory}/batteryAlert.sh both 25 98
```
This command will run script with 25% for low battery alert and 98% for high battery alert

```
/bin/bash {Directory}/batteryAlert.sh high 95
```
This command will run script with 95% for high battery alert only. It'll not alert for low battery

```
/bin/bash {Directory}/batteryAlert.sh low 20
```
This command will run script with 20% for low battery alert only. It'll not alert for high battery