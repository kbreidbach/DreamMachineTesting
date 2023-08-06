# TO DO
- Matlab Scripte path anpassen, sodass Details.xlsx nicht mehr in Aufzeichnungen
- Details.xlsx updaten (einzelne sheets überprüfen)
- Referenzen checken

# DreamMachineTesting

This repository stores all files required for or resulting from testing the quality of the DreamMachine for polysomnographic experiements.

To assess the DreamMachine's quality a nap study was conducted where each participant's (n=10) EEG, EOG, EMG and ECG was recorded on two devices simultaneously, namely the DreamMachine and the SOMNO HD eco.

The folder **Databrowser** contains Matlab figures showing the EEG and EOG traces of all measurments in 200 30-sec trials.
The images which were used in the thesis are stored in **Figures**.
All findings resulting from the comparison of the two devices are stored in **Graphoelements**, **PowerPlots** and **Spectrograms** folders and in **Details.xlsx** and **Traumemotionen_Schlafquali.ods** file.
All three **Matlab Scripts** are stored in the correspondent folder.
The measurements are saved to **Recordings**. Those obtained by the SOMNO HD eco are in .edf format and all recordings resulting from the DreamMachine are .csv files.

All .fig files can only be accessed in Matlab (version R2022a is recommended).
