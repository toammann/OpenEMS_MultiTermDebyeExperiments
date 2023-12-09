clear; clc;
addpath([pwd, filesep, 'CTB']);
addpath('../');

%fNameRes = 'sim_microstripAisler6Lay_subCond_losses';
%fNameRes = 'sim_microstripAisler6Lay_sub_losses';
fNameRes = 'sim_microstripAisler6Lay_cond_losses';
%fNameRes = 'sim_microstripAisler6Lay_no_losses';
fNameAddTimestemp = false;

freq = linspace(0.1e9, 20e9, 1001);

nPorts = 2;

%ports2Excite = 1;
ports2Excite = 1:nPorts;

runSim = 1;
viewGeom = 0;

modelDesc = {'Microstrip line with via fence on Aisler 6 layer HD stackup',...
             'Line length = combLineTabbed6G_2xthru (54.2mm) - SMA_Rosenbergerv2 fixture (28.9mm) = 23.5mm',...
             %'Substrate and Conductor losses'};
             %'Substrate losses only'};
             'Conductor losses only'};
             %'No losses'};

% ------------------------------------------------------------------------------
% -
% - Run Simulation
% -
% ------------------------------------------------------------------------------

t = tic;
sp = zeros(nPorts, nPorts, length(freq));
ports = cell(nPorts, length(ports2Excite));

for i=1:length(ports2Excite)

  % Build simulation path names
  pathSim = sprintf('sim_p%d', ports2Excite(i));
  fNameCSX = sprintf('csx_excite_p%d.xml', ports2Excite(i));

  % Run simulation
  [ports(:, ports2Excite(i)), mpDesc, mp] = microstripAisler6Lay(pathSim, fNameCSX, ports2Excite(i), freq, runSim, viewGeom);

  % Evaluate port information
  ports(:, ports2Excite(i)) = calcPort(ports(:, ports2Excite(i)), pathSim, freq, 'RefImpedance', 50);

  % Calculate S-Paramters
  for p=1:nPorts
      sp(p, ports2Excite(i),:) = ports{p, ports2Excite(i)}.uf.ref./ports{ports2Excite(i), ports2Excite(i)}.uf.inc;
  end

end

dur = toc(t);

% ------------------------------------------------------------------------------
% -
% - Plot
% -
% ------------------------------------------------------------------------------

close all;


figure;
hold on;
plot(freq/1e9,20*log10(abs(squeeze(sp(1,1,:)))),'LineWidth',2);
plot(freq/1e9,20*log10(abs(squeeze(sp(2,1,:)))),'LineWidth',2);
plot(freq/1e9,20*log10(abs(squeeze(sp(1,2,:)))),'LineWidth',2);
plot(freq/1e9,20*log10(abs(squeeze(sp(2,2,:)))),'LineWidth',2);
hold off;

grid on;
legend('S_{11}', 'S_{21}', 'S_{12}', 'S_{22}');
ylabel('S-Parameter (dB)','FontSize',12);
xlabel('frequency (GHz) \rightarrow','FontSize',12);

##
##figure;
##plotRefl(ports{1}{1}, 'fmarkers', [4e9, 6.5e9]);
##
##


% ------------------------------------------------------------------------------
% -
% - Write result file
% -
% ------------------------------------------------------------------------------

cMpVal = struct2cell(mp);
cMpNames = fieldnames(mp);

cMpDescSparse = struct2cell(mpDesc);
cMpDescNames = fieldnames(mpDesc);

cMpDesc = repmat({' '},length(cMpVal), 1);
for i=1:length(cMpDescNames)
  idx = find(strcmp(cMpDescNames(i), cMpNames));
  cMpDesc{idx} = cMpDescSparse{i};
end

comment = sprintf('\n');
comment = [comment,sprintf('!  %s\n', modelDesc{:})];
comment = [comment, sprintf('!\n!  Paramter List:\n!')];
for i=1:length(cMpNames)
  comment = [comment, sprintf('    %s = %g, %s\n!', cMpNames{i}, cMpVal{i}, cMpDesc{i})];
end

fprintf('\n');
fprintf('Write Result File...\n');

%% export sparameter to touchstone file
if fNameAddTimestemp
  resName = sprintf('%s_%s.s%dp', fNameRes, datestr(now,'yyyy-mm-dd_HHMMSS'), nPorts);
else
  resName = sprintf('%s.s%dp', fNameRes, nPorts)
end
write_touchstone('s', freq, sp, resName, 50, comment);

fprintf('Simulation duraton %fmin\n\n', dur/60);
