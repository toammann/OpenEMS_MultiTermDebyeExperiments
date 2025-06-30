% microstripAisler6Lay OpenEMS sim. script: Microstrip transmission line
%
%   Simulates simple microstrip line configuration on an AISLER 6Layer HD stackup
%   Number of ports:  2
%   Simulation time:  <10min
%
% BSD 2-Clause License
% Copyright (c) 2023, Tobias Ammann
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function [port, mpDesc, mp] = microstripAisler6Lay(pathSim, fNameCSX, excitePortN, freq, lossySubstrate, lossyCondSheet, runSim, viewGeom)

  % ----------------------------------------------------------------------------
  % -
  % - Simulation Control
  % -
  % ----------------------------------------------------------------------------

  writeFieldDumps = 1;

  % Output and Debug
  smoothMesh = 1;
  skipFixed = 1;
  writeFieldDumps = true;

  fStart = min(freq);
  fStop  = max(freq);
  energyEndCritera = -50; %dB
  %energyEndCritera = -30; %dB


  meshResEdge = 0.04; %0.02;    % Mesh resolution around microstip edges
  meshMinResFix = meshResEdge;  % Minimum resolution of fixed mesh lines

  meshResLambdaDiv = 40;        % Determines general mesh density relative to lamda (denumerator)

  physical_constants;           % Load pysical constants provided by openEMS
  unit = 1e-3;                  % all units in [mm]

  pmlWidth = 8;
  pmlStr = ['PML_', num2str(pmlWidth)];
  BC = {pmlStr pmlStr pmlStr pmlStr 'PEC' pmlStr};

  ErLambda = 1;
  lambda = c0/(fStop*sqrt(ErLambda));
  meshRes = lambda/unit/meshResLambdaDiv;

  % ----------------------------------------------------------------------------
  % -
  % - Model Parameters
  % -
  % ----------------------------------------------------------------------------

  mp.lossySubstrate = lossySubstrate;
  mpDesc.lossySubstrate = 'Flag that indicates if substrate losses were enabled';

  mp.lossyCondSheet = lossyCondSheet;
  mpDesc.lossyCondSheet = 'Flag that indicates if the zero thickness conducting sheet model was used';

  mp.w50 = 0.65;
  mpDesc.w50 = 'Width of the 50Ohm line';

  mp.w50gndfree = 1.225;
  mpDesc.w50gndfree = 'Seperation between RF trace edges to GND planes';

  % Cal line combLineTabbed6G_2xthru - SMA_Rosenberger_32K242-40ML5v2_Aisler6LayerHD_meas_ff
  mp.lineLength = 52.4 - 28.9;
  mpDesc.lineLength = 'Length of the microstrip transmission line';

  mp.portLength = 8;
  mp.measPlaneShiftP1 = mp.portLength;
  mp.measPlaneShiftP2 = mp.portLength;
  mp.feedShift = (pmlWidth+2)*meshRes;

  mp.numViasX = 55;

  mp.pcbX = mp.lineLength + 2*mp.portLength;
  mp.pcbY = 25;

  mp.stackupL01th = 0.04;
  mp.stackupSub01th = 0.13626;
  mp.stackupL02th = 0.035;
  mp.stackupSub02th = 0.2;
  mp.stackupL03th = 0.035;

  mp.viaD03  = 0.3;
  mp.viaCpD03 = 0.6;
  mp.viaClearD03 = mp.viaCpD03 + 2*0.2;
  mp.viaPitch = 0.6;

  prio.portMSL = 8;
  prio.viaDrill = 7;
  prio.viaClear = 6;
  prio.cond = 5;
  prio.air = 4;
  prio.plane = 3;
  prio.portFeedSub = 2;
  prio.sub = 1;

  % ----------------------------------------------------------------------------
  % -
  % - Simulation Setup
  % -
  % ----------------------------------------------------------------------------

  FDTD = InitFDTD('endCriteria', 10^(energyEndCritera/10));
  FDTD = SetGaussExcite(FDTD,0.5*(fStart + fStop), 0.5*(fStop - fStart));
  FDTD = SetBoundaryCond(FDTD, BC);
  CSX = InitCSX();

  % ----------------------------------------------------------------------------
  % -
  % - Material Definition
  % -
  % ----------------------------------------------------------------------------

  %Substrate Materials
  matPrePreg1080.name = 'Prepreg_1080_Panasonic-R-1551W';
  matPrePreg1080.epsR = 4.3;
  matPrePreg1080.tand = 0.013;

  matCore7628.name = 'Core_7628_Panasonic-R-1566W';
  matCore7628.epsR = 4.6;
  %matCore7628.tand = 0.012;
  matCore7628.tand = 0.02;
  %matCore7628.tand = 0.035;

  matCombined.name = 'CombinedEpsR';
  h1 = mp.stackupSub01th + mp.stackupL02th; % prepreg thickness
  h2 = mp.stackupSub02th;                   % core thickness
  matCombined.epsR =  matPrePreg1080.epsR*matCore7628.epsR*(h1+h2)/(h1*matCore7628.epsR + h2*matPrePreg1080.epsR);

  if lossySubstrate
    mMin = 6;

    CSX = AddDjordjevicSarkarMaterial(CSX, matPrePreg1080.name,...
                                           'fMeas', 6e9, 'epsRMeas', matPrePreg1080.epsR, 'tandMeas', matPrePreg1080.tand,...
                                           'f1', 10^mMin/(2*pi), 'f2', 200e9, 'plotEn', 1);

    CSX = AddDjordjevicSarkarMaterial(CSX, matCore7628.name,...
                                           'fMeas', 6e9,  'epsRMeas', matCore7628.epsR, 'tandMeas', matCore7628.tand,...
                                           'f1', 10^mMin/(2*pi), 'f2', 200e9);
  else
    CSX = AddMaterial(CSX,          matPrePreg1080.name);
    CSX = SetMaterialProperty( CSX, matPrePreg1080.name, 'Epsilon', matPrePreg1080.epsR, 'Mue', 1);
    CSX = AddMaterial(CSX,          matCore7628.name);
    CSX = SetMaterialProperty( CSX, matCore7628.name, 'Epsilon', matCore7628.epsR, 'Mue', 1);
  end

  CSX = AddMaterial(CSX,          matCombined.name);
  CSX = SetMaterialProperty( CSX, matCombined.name,'Epsilon', matCombined.epsR, 'Mue', 1, 'Kappa', 0.04);

  % Conducting sheet and PEC
  if lossyCondSheet

      sigmaCopper = 56e6;

      CSX = AddConductingSheet(CSX,'CondL01_Port', sigmaCopper, mp.stackupL01th*unit);
      CSX = AddConductingSheet(CSX,'CondL01_Line', sigmaCopper, mp.stackupL01th*unit);
      CSX = AddConductingSheet(CSX,'CondL01', sigmaCopper, mp.stackupL01th*unit);
      CSX = AddConductingSheet(CSX,'CondL02', sigmaCopper, mp.stackupL02th*unit);
      CSX = AddConductingSheet(CSX,'CondL03', sigmaCopper, mp.stackupL03th*unit);

      % Model the metal layers as zero thickness
      mp.stackupL01th = 0;
      mp.stackupL02th = 0;
      mp.stackupL03th = 0;

    else

      CSX = AddMetal(CSX, 'ViaDrill');
      %CSX = AddMetal(CSX, 'ViaCp');
      CSX = AddMetal(CSX, 'CondL01_Port');
      CSX = AddMetal(CSX, 'CondL01_Line');
      CSX = AddMetal(CSX, 'CondL01');
      CSX = AddMetal(CSX, 'CondL02');
      CSX = AddMetal(CSX, 'CondL03');

  end


  CSX = AddMetal(CSX, 'ViaDrill'); % 3D shape, this cannot be a conducting sheet

  % ----------------------------------------------------------------------------
  % -
  % - 3D Model - Via Definitions
  % -
  % ----------------------------------------------------------------------------

  viaType03gnd.cp = [,...
    struct('en', 0, 'diam', mp.viaCpD03, 'matName', 'ViaCp', 'prio', prio.cond),...
    struct('en', 0, 'diam', mp.viaCpD03, 'matName', 'ViaCp', 'prio', prio.cond),...
    struct('en', 0, 'diam', mp.viaCpD03, 'matName', 'ViaCp', 'prio', prio.cond)];

  viaType03gnd.clear = [,...
    struct('en', 0, 'diam', mp.viaClearD03, 'matName', 'Air', 'prio', prio.viaClear),...
    struct('en', 0, 'diam', mp.viaClearD03, 'matName', matPrePreg1080.name, 'prio', prio.viaClear),...
    struct('en', 0, 'diam', mp.viaClearD03, 'matName', 'Air', 'prio', prio.viaClear)]; %This wont be needed...

  viaType03gnd.drill  = struct('diam', mp.viaD03,...
                               'matName', 'ViaDrill',...
                               'prio', prio.viaDrill);

  % ----------------------------------------------------------------------------
  % -
  % - 3D Model - Stackup
  % -
  % ----------------------------------------------------------------------------

  posX.stackup(1) =  mp.pcbX/2;
  posX.stackup(2) = -mp.pcbX/2;

  posY.stackup(1) = -mp.pcbY/2;
  posY.stackup(2) = -mp.w50gndfree - mp.w50/2;
  posY.stackup(3) =  mp.w50gndfree + mp.w50/2;
  posY.stackup(4) =  mp.pcbY/2;

  posZ.stackup(1)  = 0;                                       % Top surface
  posZ.stackup(2)  = -mp.stackupL01th;                        % L01 metal
  posZ.stackup(3)  = posZ.stackup(end) - mp.stackupSub01th;   % Sub01 Prepreg
  posZ.stackup(4)  = posZ.stackup(end) - mp.stackupL02th;     % L02 metal
  posZ.stackup(5)  = posZ.stackup(end) - mp.stackupSub02th;   % Sub02 Core
  posZ.stackup(6)  = posZ.stackup(end) - mp.stackupL03th;     % L03 metal

  % L01 - Top Layer
  start = [posX.stackup(1), posY.stackup(1), posZ.stackup(1)];
  stop =  [posX.stackup(2), posY.stackup(2), posZ.stackup(2)];
  CSX = AddBox(CSX, 'CondL01', prio.cond, start, stop);

  start(2) = -start(2);
  stop(2) = -stop(2);
  CSX = AddBox(CSX, 'CondL01', prio.cond, start, stop);

  % Substrate 01 - Prepreg
  start = [posX.stackup(1), posY.stackup(1), posZ.stackup(2)];
  stop =  [posX.stackup(2), posY.stackup(end), posZ.stackup(3)];
  CSX = AddBox(CSX, matPrePreg1080.name, prio.sub, start, stop);

  % L02
  start = [posX.stackup(1), posY.stackup(1),       posZ.stackup(3)];
  stop =  [posX.stackup(2), posY.stackup(2), posZ.stackup(4)];
  CSX = AddBox(CSX, 'CondL02', prio.cond, start, stop);

  start(2) = -start(2);
  stop(2) = -stop(2);
  CSX = AddBox(CSX, 'CondL02', prio.cond, start, stop);

  % Substrate 02 - Core
  start = [posX.stackup(1), posY.stackup(1), posZ.stackup(4)];
  stop =  [posX.stackup(2), posY.stackup(end), posZ.stackup(5)];
  CSX = AddBox(CSX, matCore7628.name, prio.sub, start, stop);

  % L03
  start = [posX.stackup(1), posY.stackup(1), posZ.stackup(5)];
  stop =  [posX.stackup(2), posY.stackup(end), posZ.stackup(6)];
  CSX = AddBox(CSX, 'CondL03', prio.plane, start, stop);

  % ----------------------------
  % GND Plane - Prepreg fill (L02)
  % ----------------------------

  if ~lossyCondSheet
    start = [posX.stackup(1), posY.stackup(1), posZ.stackup(3)];
    stop =  [posX.stackup(2), posY.stackup(end), posZ.stackup(4)];
    CSX = AddBox(CSX, matPrePreg1080.name, prio.sub, start, stop);
  end

  % ----------------------------------------------------------------------------
  % -
  % - 3D Model: Microstrip
  % -
  % ----------------------------------------------------------------------------

  posX.msLine(1) = -mp.pcbX/2 + mp.portLength;
  posX.msLine(2) =  mp.pcbX/2 - mp.portLength;

  posY.msLine(1) = -mp.w50/2;
  posY.msLine(2) =  mp.w50/2;

  start = [posX.msLine(1), posY.msLine(1), posZ.stackup(1)];
  stop =  [posX.msLine(2), posY.msLine(2), posZ.stackup(2)];
  CSX = AddBox(CSX, 'CondL01_Line', prio.cond, start, stop);

  [posX.line, posY.line] = meshBoxThirdsRule(start, stop, meshResEdge, [0, 1], [0,1]);

  % ----------------------------------------------------------------------------
  % -
  % - 3D Model - Via Fence
  % -
  % ----------------------------------------------------------------------------

 % GND Via Resonator 1
  posSouth = [ 0,...                                      % X
              -mp.w50/2 - mp.w50gndfree - mp.viaCpD03/2]; % Y

  posNorth = [ 0,...                                      % X
              mp.w50/2 + mp.w50gndfree + mp.viaCpD03/2];  % Y

  posSouth(1) = posSouth(1) - mp.viaPitch*floor(mp.numViasX/2);
  posNorth(1) = posNorth(1) - mp.viaPitch*floor(mp.numViasX/2);

  posX.ViaSouth = [];
  posY.ViaSouth = [];
  posX.ViaNorth = [];
  posY.ViaNorth = [];

  for i=1:mp.numViasX

    [CSX, posX.ViaSouth, posY.ViaSouth] = constructVia(CSX, posSouth, posZ.stackup, viaType03gnd, posX.ViaSouth, posY.ViaSouth);
    [CSX, posX.ViaNorth, posY.ViaNorth] = constructVia(CSX, posNorth, posZ.stackup, viaType03gnd, posX.ViaNorth, posY.ViaNorth);

    posSouth(1) = posSouth(1) + mp.viaPitch;
    posNorth(1) = posNorth(1) + mp.viaPitch;
  end

  % ------------------------------------------------------------------------------
  % -
  % - Microstrip Ports, Define Positions
  % -
  % ------------------------------------------------------------------------------

  % Ports
  posX.portMSL1(1) = -mp.pcbX/2;
  posX.portMSL1(2) = -mp.pcbX/2 + mp.measPlaneShiftP1;
  posX.portMSL1(3) = -mp.pcbX/2 + mp.portLength;
  posX.portMSL1(4) = -mp.pcbX/2 + mp.feedShift;

  posX.portMSL2(1) = mp.pcbX/2;
  posX.portMSL2(2) = mp.pcbX/2 - mp.measPlaneShiftP1;
  posX.portMSL2(3) = mp.pcbX/2 - mp.portLength;
  posX.portMSL2(4) = mp.pcbX/2 - mp.feedShift;

  posY.portMSL1(1) = -mp.w50/2;
  posY.portMSL1(2) =  mp.w50/2;
  posY.portMSL2 = posY.portMSL1;

  % ----------------------------------------------------------------------------
  % -
  % - Mesh in X-Dimension
  % -
  % ----------------------------------------------------------------------------

  % Collect fixed mesh lines from positions
  fixMeshX = [,...
    posX.portMSL1(2:3),...
    posX.portMSL2(2:3),...
    posX.line,...
    posX.stackup,...
    posX.ViaNorth,...
    posX.ViaSouth,...
    ];

  if skipFixed
    meshXFixed = sort(skipFixedMeshLine(fixMeshX, meshMinResFix, true));
  else
    meshXFixed = fixMeshX;
  end

  meshXfineMin = posX.portMSL1(2);
  meshXfineMax = posX.portMSL2(2);

  idxMin = find(meshXFixed == meshXfineMin) - 3;
  idxMax = find(meshXFixed == meshXfineMax) + 3;

  meshXfine = meshXFixed(idxMin:idxMax);
  meshXFixed(idxMax:idxMin) = []; # remove the fine section

  if smoothMesh
    meshXfine  = SmoothMeshLines(meshXfine, meshRes/2, 1.5);
    meshGrid.x = SmoothMeshLines([meshXfine, meshXFixed], meshRes, 1.6);
  else
    meshGrid.x = meshXFixed;
  end

  % ----------------------------------------------------------------------------
  % -
  % Mesh in Y-Dimension
  % -
  % ----------------------------------------------------------------------------

  fixMeshY = [,...
    #posY.portMSL1,...
    #posY.portMSL2,...
    posY.line,...
    posY.stackup,...
    posY.ViaNorth,...
    posY.ViaSouth,...
    ];

  if skipFixed
    meshYFixed = sort(skipFixedMeshLine(fixMeshY, meshMinResFix, true));
  else
    meshYFixed = fixMeshY;
  end

  meshYfineMin =  -mp.w50/2 - mp.w50gndfree - mp.viaCpD03/2 - mp.viaD03/2;
  meshYfineMax =  -meshYfineMin;

  idxMin = find(meshYFixed == meshYfineMin);
  idxMax = find(meshYFixed == meshYfineMax);

  meshYfine = meshYFixed(idxMin:idxMax);
  meshYFixed(idxMax:idxMin) = []; # remove the fine section

  if smoothMesh
    meshYfine  = SmoothMeshLines(meshYfine, meshResEdge*6, 1.2);
    meshGrid.y = SmoothMeshLines([meshYfine, meshYFixed], meshRes);
  else
    meshGrid.y = [meshYfine, meshYFixed];
  end

  % ----------------------------------------------------------------------------
  % -
  % Mesh in Z-Dimension
  % -
  % ----------------------------------------------------------------------------

  meshGrid.z(1) = posZ.stackup(end) - lambda/4/unit*0;
  meshGrid.z(2) = posZ.stackup(1)   + lambda/4/unit*2;

  if smoothMesh
    meshZfine = SmoothMeshLines(posZ.stackup, mp.stackupSub01th/3.2, 1.5);
    meshGrid.z = SmoothMeshLines([meshGrid.z, meshZfine], meshRes, 1.1);
  else
    meshGrid.z = [meshGrid.z, posZ.stackup];
  end

  % ----------------------------------------------------------------------------
  % -
  % OpenEMS Mesh Grid
  % -
  % ----------------------------------------------------------------------------

  % add lines in the positve z direction only
  meshGrid = AddPML(meshGrid, [0 0 0 0 0 pmlWidth]);

  CSX = DefineRectGrid( CSX, unit, meshGrid);

  % ----------------------------------------------------------------------------
  % -
  % - Microstrip Port Definition
  % -
  % ----------------------------------------------------------------------------

##  posY.portMSL1(1) = min(posY.line);
##  posY.portMSL1(2) = max(posY.line);
##
##  start = [posX.portMSL1(3), posY.portMSL1(1), posZ.stackup(2)];
##  stop =  [posX.portMSL1(3), posY.portMSL1(2), posZ.stackup(5)];
##  [CSX, port{1}] = AddLumpedPort(CSX, prio.portMSL, 1, 50, start, stop, [0 0 1], excitePortN == 1);
##
##
##  start = [posX.portMSL2(3), posY.portMSL2(1), posZ.stackup(2)];
##  stop =  [posX.portMSL2(3), posY.portMSL2(2), posZ.stackup(5)];
##   [CSX, port{2}] = AddLumpedPort(CSX, prio.portMSL, 2, 50, start, stop, [0 0 1], excitePortN == 2);

  % Define Port 1
  start = [posX.portMSL1(1), posY.portMSL1(1), posZ.stackup(2)];
  stop =  [posX.portMSL1(3), posY.portMSL1(2), posZ.stackup(5)];


  [CSX, port{1}] = AddMSLPort( CSX, prio.portMSL, 1, 'CondL01_Port', start, stop, 'x', [0 0 -1],...
      'ExcitePort', excitePortN == 1,...
      'FeedShift', mp.feedShift,...
      'MeasPlaneShift', mp.measPlaneShiftP1);

  % Add a metallic box on top of the microstip port. This solves a static charge problem
  if ~lossyCondSheet
    CSX = AddBox(CSX, 'CondL01_Port', prio.portMSL,  [start(1:2),posZ.stackup(1)] , [stop(1:2),posZ.stackup(2)]);
  end

  if (excitePortN == 1)
      start(1) = posX.portMSL1(4) - meshRes;
      stop(1)  = posX.portMSL1(4) + meshRes;

      CSX = AddBox(CSX, matCombined.name, prio.portFeedSub,  start, stop);
  end

  % Define Port 2
  start = [posX.portMSL2(1), posY.portMSL2(1), posZ.stackup(2)];
  stop =  [posX.portMSL2(3), posY.portMSL2(2), posZ.stackup(5)];

  [CSX, port{2}] = AddMSLPort( CSX, prio.portMSL, 2, 'CondL01_Port', start, stop, 'x', [0 0 -1],...
      'ExcitePort', excitePortN == 2,...
      'FeedShift', mp.feedShift,...
      'MeasPlaneShift', mp.measPlaneShiftP2);

  if ~lossyCondSheet
    CSX = AddBox(CSX, 'CondL01_Port', prio.portMSL,  [start(1:2),posZ.stackup(1)] , [stop(1:2),posZ.stackup(2)]);
  end

  if (excitePortN == 2)
      start(1) = posX.portMSL2(4) - meshRes;
      stop(1)  = posX.portMSL2(4) + meshRes;
      CSX = AddBox(CSX, matCombined.name, prio.portFeedSub,  start, stop);
  end

  port = port.'; % Return a row vector

  % ----------------------------------------------------------------------------
  % -
  % - Dump Boxes (Field Monitors)
  % -
  % ----------------------------------------------------------------------------

  if writeFieldDumps
    CSX = AddDump(CSX,'Et_xz');
    start = [meshGrid.x(1),   0, meshGrid.z(1)];
    stop =  [meshGrid.x(end), 0, meshGrid.z(end)];
    CSX = AddBox(CSX,'Et_xz',0 , start,stop);
  end

  % ----------------------------------------------------------------------------
  %
  % - Write OpenEMS xml file
  % -
  % ----------------------------------------------------------------------------

  if runSim && exist(pathSim, 'dir')
    confirm_recursive_rmdir(0); % Disable remove directiony user confirmation
    rmdir( pathSim, 's' );      % clear simulation directory
  end

  mkdir( pathSim );      % create empty simulation folder
  WriteOpenEMS([pathSim, filesep, fNameCSX], FDTD, CSX);

  % ----------------------------------------------------------------------------
  %
  % - View Geometry
  % -
  % ----------------------------------------------------------------------------

  if viewGeom
    CSXGeomPlot([pathSim, filesep, fNameCSX]);
  end

  % ----------------------------------------------------------------------------
  %
  % - Run Simulation
  % -
  % ----------------------------------------------------------------------------

  if runSim
    fprintf('\n');
    fprintf('-------------------------------------------------------------------\n\n');
    fprintf('  Starting exciation of Port %d...\n\n', excitePortN);
    fprintf('-------------------------------------------------------------------\n');
    fprintf('\n');
    RunOpenEMS( pathSim, fNameCSX ,'--debug-PEC');
    #RunOpenEMS( pathSim, fNameCSX, '--numThreads=6');
    #RunOpenEMS( pathSim, fNameCSX);
  end
end
