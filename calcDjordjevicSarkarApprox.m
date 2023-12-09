##close all;
##clear

##tandMeas = 0.02;
##epsRMeas = 4.3;
##fMeasSarkar = 10e9;
%m2 = 12;
%calcDjordjevicSarkarApprox(4.3, 0.013, 1e9, 200e9, 'f1', 10^4/(2*pi), 'plotEn', 'plotMeasData', datasheetVal);
%calcDjordjevicSarkarApprox(4.6, 0.012, 6e9, 200e9, 'f1', 10^4/(2*pi), 'plotEn', 'plotMeasData', datasheetVal);
%[paramLorentz, paramDebye, paramSarkar] = calcDjordjevicSarkarApprox(4.3, 0.02, 10e9, 10^12/(2*pi), 'lowFreqEvalType', 0, 'f1', 10^4/(2*pi), 'sigma', 80e-12, 'nTermsPerDec', 1, 'plotEn');
%[paramLorentz, paramDebye, paramSarkar] = calcDjordjevicSarkarApprox(4.3, 0.02, 10e9, 10^12/(2*pi), 'lowFreqEvalType', 1, 'epsDC', 5.3, 'sigma', 80e-12, 'nTermsPerDec', 1, 'plotEn', 1);

function [paramLorentz, paramDebye, paramSarkar] = calcDjordjevicSarkarApprox(varargin)
   p = inputParser();

   p.addRequired('epsRMeas', @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addRequired('tandMeas', @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addRequired('fMeas',    @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addRequired('f2',       @(x) (x >= 0) && isnumeric(x) && isscalar(x));

   p.addParameter('lowFreqEvalType',0, @(x) (x >= 0) && (round(x) == x)  && isscalar(x));
   p.addParameter('f1', [],            @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addParameter('epsDC', [],         @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addParameter('sigma', 0,          @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addParameter('nTermsPerDec', 1,   @(x) (x >= 1) && isnumeric(x) && isscalar(x));
   p.addParameter('plotMeasData', [],  @isstruct);

   p.addSwitch('plotEn');

   p.FunctionName = 'calcDjordjevicSarkarApprox';
   p.parse(varargin{:})

   if ((p.Results.lowFreqEvalType == 0) && any(strcmp(p.UsingDefaults, 'f1')))
     error('For ''lowFreqEvalType=0'' a value for f1 must be specified.');
   end

   if ((p.Results.lowFreqEvalType == 1) && any(strcmp(p.UsingDefaults, 'epsDC')))
     error('For ''lowFreqEvalType=1'' a value for epsDC must be specified.');
   end

  epsRMeas = p.Results.epsRMeas;
  tandMeas = p.Results.tandMeas;
  fMeasSarkar = p.Results.fMeas;
  f2 = p.Results.f2;

  lowFreqEvalType = p.Results.lowFreqEvalType;
  f1 = p.Results.f1;
  epsDC = p.Results.epsDC;
  sigma = p.Results.sigma; % S/m
  nTermsPerDec = p.Results.nTermsPerDec;

  m2 = log10(f2*2*pi);
  m1 = log10(f1*2*pi);
  eps0 = 8.8541878128e-12; %F/m

  wMeasSarkar = 2*pi*fMeasSarkar;

  % ------------------------------------------------------------------------------
  % -
  % - Calculate Djordjevic-Sarkar parameters
  % -
  % ------------------------------------------------------------------------------

  w2 = 10^m2;

  if lowFreqEvalType == 0
    % Standard Djordjevic Sarkar. Low frequency behaviour defined by w1 = 10^(m1).
    % Lower corner frequency, No approximations necessary --> use exact formulas
    w1 = 10^m1;

    k = log(10)*(-tandMeas*epsRMeas - sigma/(eps0*wMeasSarkar));
    k = k/arg((w2 + 1i*wMeasSarkar)/(w1 + 1i*wMeasSarkar));

    epsInfSarkar = epsRMeas - k*log10(abs((w2 + 1i*wMeasSarkar)/(w1 + 1i*wMeasSarkar)));
    depsTSarkar = k*(m2-m1);

  else
    % Alternative definition: Specify epsDC (permittivity at DC)
    % calculate the lowMeasDebyer corner frequency from this value

    k = log(10)*(-tandMeas*epsRMeas - sigma/(eps0*wMeasSarkar))/atan2(-w2,wMeasSarkar);
    epsInfSarkar = epsRMeas - k*log10(sqrt(w2^2 + wMeasSarkar^2)/wMeasSarkar);

    depsTSarkar = epsDC - epsInfSarkar;
    m1 = m2 - depsTSarkar/k;
    w1 = 10^m1;

    if m1 < 0
      error('DjordjevicSarkar m1 < 1. Value for ''epsDC'' is too high, choose a lower one');
    endif

  end

  mPlotmin = m1-3;
  if mPlotmin < 10; mPlotmin = 1; end
  f = logspace(mPlotmin, m2+2, 1001);
  w = 2*pi*f;

  % ------------------------------------------------------------------------------
  % -
  % - Calculate Djordjevic-Sarkar model (no approximations)
  % -
  % ------------------------------------------------------------------------------

  % Model equation
  epsRSarkarEq = @(x) epsInfSarkar + depsTSarkar/(m2-m1)*log10((w2+1i*x)./(w1+1i*x)) - 1i*sigma./(x*eps0);
  epsRSarkar = epsRSarkarEq(w);
  tandSarkar = -imag(epsRSarkar)./real(epsRSarkar);

  paramSarkar.epsInf = epsInfSarkar;
  paramSarkar.m1 = m1;
  paramSarkar.m2 = m2;
  paramSarkar.depsT = depsTSarkar;
  paramSarkar.sigma = sigma;

  % Approximations
  epsRSarkarTapprox = epsInfSarkar + depsTSarkar/(m2-m1)*log10(w2./w);
  epsRSarkarTTapprox = -depsTSarkar/(m2-m1)*(-pi/2)/log(10); % - 1i*sigma./(w*eps0);

  % ------------------------------------------------------------------------------
  % -
  % - Calculate Mulit-Term Debye
  % -
  % ------------------------------------------------------------------------------

  % Debeye Pole locations
  mMin = m1+1;
  mMax = m2;

  mi = mMin:1/nTermsPerDec:mMax;
  wi = 10.^(mi.');
  nTerms = length(mi);

  % Measured frequencies to use for fit, choose  in a way that the imaginary
  % part oscillates around the value of the Sarkar model
  msp = 10^((log10(wi(2)) - log10(wi(1)))/4);
  wMeasDebye = wi*msp; % Measured frequencies to use for fit

  % Determine deltaEpsilonTick_i from a known imaginary value
  A = 1./(wi.'./wMeasDebye + wMeasDebye./wi.');
  epsTTdebye = -imag(epsRSarkarEq(wMeasDebye));
  depsTDebye = A\epsTTdebye; % Solve linear equation system

  wx = wMeasSarkar;
  sumDebyeT = sum(depsTDebye./(1 + wx^2./wi.^2), 1); % real part
  epsInfDebye = epsInfSarkar + depsTSarkar/(m2-m1)*log10(abs((w2+1i*wx)/(w1+1i*wx))) - sumDebyeT;

  % Model equation
  sumDebye = sum(depsTDebye./(1 + 1i*w./wi), 1);
  epsRDebye = epsInfDebye + sumDebye - 1i*sigma./(w*eps0);
  tandDebye = -imag(epsRDebye)./real(epsRDebye);

  paramDebye.epsInf = epsInfDebye;
  paramDebye.depsT = depsTDebye;
  paramDebye.wi = wi;
  paramDebye.sigma = sigma;

  % ------------------------------------------------------------------------------
  % -
  % - Calculate Mulit-Term Lorentz
  % -
  % ------------------------------------------------------------------------------

  epsInfLorentz = epsInfDebye;

  kLor = 1/10;
  fl = wi(end)/sqrt(kLor)/(2*pi);

  fp = sqrt(depsTDebye*fl^2/epsInfLorentz);
  taup = wi/(4*pi^2 * fl^2);

  % Model Equation
  sumLorentz = sum((epsInfLorentz*fp.^2)./(f.^2 - fl^2 - 1i*f./(2*pi*taup)), 1);
  epsRLorentz = epsInfLorentz - sumLorentz - 1i*sigma./(w*eps0);
  tandLorentz = -imag(epsRLorentz)./real(epsRLorentz);

  paramLorentz.fp = fp;
  paramLorentz.fl = fl;
  paramLorentz.taup = taup;
  paramLorentz.epsInf = epsInfLorentz;
  paramLorentz.sigma = sigma;
  % ------------------------------------------------------------------------------
  % -
  % - Debug Plots / Logarithmic frequency axis
  % -
  % ------------------------------------------------------------------------------

  if p.Results.plotEn

    screenSize = get(0, 'screensize');
    %figLogPos = get(figLog, 'Position');
    %figLinPos = get(figLin, 'Position');
    figPos = [screenSize(3)/2, screenSize(4)/2, 800, 600];
    figLogPos = figPos + [-figPos(3), -figPos(4)/2, 0, 0] ;
    figLinPos = figPos + [ 0,         -figPos(4)/2, 0, 0] ;

    legendCell = {'Djordjevic-Sarkar', 'Multi-Term Debye', 'Multi-Term Lorentz (openEMS)'};

    figLog = figure('Position', figLogPos);
    subplot(2,1,1);
    semilogx(f, real(epsRSarkar)); hold on;
    semilogx(f, real(epsRDebye));
    semilogx(f, real(epsRLorentz));
    %semilogx(f, epsRSarkarTapprox);

    if ~isempty(p.Results.plotMeasData)
      semilogx(p.Results.plotMeasData.f, p.Results.plotMeasData.epsR);
      legendCell = [legendCell, 'Measured Data'];
    end

    grid on;
    ylabel('\epsilon''');
    xlabel('Frequency / Hz');
    legend(legendCell);
    title(sprintf(['Wideband Dielectric Model: \\epsilon_r = %.1f, tan_\\delta =%.3f,'...
      ' f_{fit}=%.1fGHz, Order=%d'], epsRMeas, tandMeas, fMeasSarkar/1e9, nTerms));


    % --------------------------------------------------------------------------

    subplot(2,1,2);
    semilogx(f, -imag(epsRSarkar)); hold on;
    semilogx(f, -imag(epsRDebye));
    semilogx(f, -imag(epsRLorentz));
    %semilogx(f, epsRSarkarTTapprox);

    if ~isempty(p.Results.plotMeasData)
      semilogx(p.Results.plotMeasData.f, p.Results.plotMeasData.tand.*p.Results.plotMeasData.epsR);
    end

    hold off;
    ylabel('\epsilon''''');
    xlabel('Frequency / Hz');
    grid on;

    % ------------------------------------------------------------------------------
    % -
    % - Debug Plots / Linear frequency axis
    % -
    % ------------------------------------------------------------------------------
    [~, maxPlotIdx] = min(abs(f - 10^(m2-1)/2/pi));


    figLin = figure('Position', figLinPos);

    subplot(2,1,1);
    plot(f(1:maxPlotIdx)/1e9, real(epsRSarkar(1:maxPlotIdx))); hold on;
    plot(f(1:maxPlotIdx)/1e9, real(epsRDebye(1:maxPlotIdx)));
    plot(f(1:maxPlotIdx)/1e9, real(epsRLorentz(1:maxPlotIdx)));

    if ~isempty(p.Results.plotMeasData)
      plot(p.Results.plotMeasData.f/1e9, p.Results.plotMeasData.epsR);
    end

    hold off;
    grid on;
    ylabel('\epsilon''');
    xlabel('Frequency / GHz');
    legend(legendCell);
    title(sprintf('Wideband Dielectric Model: \\epsilon_r = %.1f, tan_\\delta =%.3f, f_{fit}=%.1fGHz, Order=%d', epsRMeas, tandMeas, fMeasSarkar/1e9, nTerms));
    %xlim([0, f(maxPlotIdx)/1e9]);

    % --------------------------------------------------------------------------

    subplot(2,1,2);
    plot(f(1:maxPlotIdx)/1e9, tandSarkar(1:maxPlotIdx)); hold on;
    plot(f(1:maxPlotIdx)/1e9, tandDebye(1:maxPlotIdx));
    plot(f(1:maxPlotIdx)/1e9, tandLorentz(1:maxPlotIdx));

    if ~isempty(p.Results.plotMeasData)
      plot(p.Results.plotMeasData.f/1e9, p.Results.plotMeasData.tand);
    end

    hold off;
    grid on;
    ylabel('tan_\delta');
    xlabel('Frequency / GHz');
    %xlim([0, f(maxPlotIdx)/1e9]);

    %semilogx(datasheetVal.f, datasheetVal.er); hold off;


    %figLinPos(1) = figLinPos(1) + figLogPos(3);
  end
end
