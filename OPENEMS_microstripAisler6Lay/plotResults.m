clear;
close all;

% Plot Size and scaling
size_x = 1280;
size_y = 720;

% Parse Touchstone
[~, freq_noLosses, sp_noLosses]=read_touchstone('sim_microstripAisler6Lay_no_losses.s2p');
[~, freq_condLosses, sp_condLosses]=read_touchstone('sim_microstripAisler6Lay_cond_losses.s2p');
[~, freq_subLosses, sp_subLosses]=read_touchstone('sim_microstripAisler6Lay_sub_losses.s2p');
[~, freq_subCondLosses, sp_subCondLosses]=read_touchstone('sim_microstripAisler6Lay_subCond_losses.s2p');
[~, freq_meas sp_meas]=read_touchstone('combLineTabbed6G_2xthru_deemb.s2p');

dB = @(x) 20*log10(abs(squeeze(x)));

% ------------------------------------------------------------------------------
% -
% - Plot 1: Transmission
% -
% ------------------------------------------------------------------------------

% Create Figure 1
fig1 = figure('Position', [0,0, size_x, size_y]);

% Plot Lines
hold on;
plot(freq_noLosses/1e9, dB(sp_noLosses(2,1,:)), 'Linewidth', 1.5);
plot(freq_condLosses/1e9, dB(sp_condLosses(2,1,:)), 'Linewidth', 1.5);
plot(freq_subLosses/1e9, dB(sp_subLosses(2,1,:)), 'Linewidth', 1.5);
plot(freq_subCondLosses/1e9, dB(sp_subCondLosses(2,1,:)), 'Linewidth', 1.5);
plot(freq_meas/1e9, dB(sp_meas(2,1,:)), 'Linewidth', 1.5);
hold off;

% Plot Texts
legend( 'openEMS - lossless',...
        'openEMS - condSheet only',...
        'openEMS - Djordjevic only',...
        'openEMS - Djordjevic+CondSheet',...
        'De-embedded Measurement ',...
        'FontSize', 11,...
        'Location', 'SouthWest');

title({'Microstrip on Aisler 6 Layer HD - Transmission S_{21}',...
       'Simulation vs. Measurment'});
xlabel('Frequency / GHz');
ylabel('Magnitude / dB');
grid minor

print(fig1, 'meas_vs_sim_s21.png', '-dpng', sprintf('-S%i,%i', size_x, size_y));


% ------------------------------------------------------------------------------
% -
% - Plot 2: Reflection
% -
% ------------------------------------------------------------------------------

% Create Figure 2
fig2 = figure('Position', [0,0, size_x, size_y]);

% Plot Lines
hold on;
plot(freq_noLosses/1e9, dB(sp_noLosses(1,1,:)), 'Linewidth', 1.5);
plot(freq_condLosses/1e9, dB(sp_condLosses(1,1,:)), 'Linewidth', 1.5);
plot(freq_subLosses/1e9, dB(sp_subLosses(1,1,:)), 'Linewidth', 1.5);
plot(freq_subCondLosses/1e9, dB(sp_subCondLosses(1,1,:)), 'Linewidth', 1.5);
plot(freq_meas/1e9, dB(sp_meas(1,1,:)), 'Linewidth', 1.5);
hold off;

% Plot Texts
legend( 'openEMS - lossless',...
        'openEMS - condSheet only',...
        'openEMS - Djordjevic only',...
        'openEMS - Djordjevic+CondSheet',...
        'De-embedded Measurement ',...
        'FontSize', 11,...
        'Location', 'SouthWest');


title({'Microstrip on Aisler 6 Layer HD - Reflection S_{11}',...
       'Simulation vs. Measurment'});
xlabel('Frequency / GHz');
ylabel('Magnitude / dB');
grid minor

print(fig2, 'meas_vs_sim_s11.png', '-dpng', sprintf('-S%i,%i', size_x, size_y));
% ------------------------------------------------------------------------------
% -
% - Plot 3: Measurmed Transmission line
% -
% ------------------------------------------------------------------------------

% Create Figure 1
fig3 = figure('Position', [0,0, size_x, size_y]);

% Plot Lines
hold on;
plot(freq_meas/1e9, dB(sp_meas(1,1,:)), 'Linewidth', 1.5);
plot(freq_meas/1e9, dB(sp_meas(2,1,:)), 'Linewidth', 1.5);
plot(freq_meas/1e9, dB(sp_meas(1,2,:)), 'Linewidth', 1.5);
plot(freq_meas/1e9, dB(sp_meas(2,2,:)), 'Linewidth', 1.5);
hold off;

ylim([-50,0]);

% Plot Texts
legend( 'S_{11}', 'S_{21}', 'S_{12}', 'S_{22}', 'FontSize', 11, 'Location', 'SouthWest');

title({'Microstrip on Aisler 6 Layer HD',...
       'De-Embedded Measurment (23.5mm)'});
xlabel('Frequency / GHz');
ylabel('Magnitude / dB');
grid minor

print(fig3, 'meas_deemb.png', '-dpng', sprintf('-S%i,%i', size_x, size_y));


