# WindPower Base Load model
---------
[![license](https://img.shields.io/badge/license-Apache%202.0-black)](https://github.com/AxelHallander/Windpower-base-load-model/blob/main/LICENSE.md)
[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=[windpower-base-load-model]&project=MY_REPO.prj)

<?xml version="1.0" encoding="UTF-8"?>
<MATLABProject xmlns="http://www.mathworks.com/MATLABProjectFile" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0"/>

--------- 
This is a model in Matlab that simulates a system of off-shore wind turbines and two kinds of energy storages with the aim to show the possibility of providing a base load to the EU. Wind wind speed data from copernicus across europe, wind parks can be simulated. Each of these wind parks are to provide a part of the EU baselaod with the help of a small local storage. First the wind park it self tries to suffice the baseload. If this cannot be acheived all parks in a defined region communicates and sends surplus power and deficit power requests and tries to balance the difference. The next step, if this still is not sufficient, transmission across regions occurs in a similar fashion. Lastly, if this still is not enough a regional large central storage can dispatach or charge energy to balance out the power. 

---------
# License

Copyright 2024 AxelHallander under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
