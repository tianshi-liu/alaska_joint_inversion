Ambient noise and earthquake dataset used by Alaska adjoint tomography

Ambient noise dataset:
  file sources.dat list all virtual sources
  for each virtual source:
    FORCESOLUTION describes the point force used for simulation
    STATIONS lists all virtual receivers
    MEASUREMENT.WINDOWS.{COMPONENT}.{BAND} list all the measurement windows that pass quality control, with format of:
      TOTOL_NUMBER_OF_WINDOWS
      VIRTUAL_RECEIVER_1
      START_TIME END_TIME
      VIRTUAL_RECEIVER_2
      START_TIME END_TIME
      ...


Earthquake dataset:
  file event_filtered.lst lists all earthquakes
  for each earthquake:
    CMTSOLUTION describes the CMT solution used for simulation
    STATIONS lists all receivers
    MEASUREMENT.WINDOWS_PAIR.{COMPONENT}.{BAND} list all the window pairs that pass quality control, with format of:
    INDEX_OF_STATION1 INDEX_OF_STATION2 START_TIME_1 START_TIME_2 AZIMUTH_DIFFERENCE CORRELATION_COEFFICIENT
