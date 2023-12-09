%AddDjordjevicSarkarMaterial(4.6, 0.012, 5e9, 200e9, 'f1', 10^4/(2*pi), 'sigma', 10e-15);

  %CSX = AddDjordjevicSarkarMaterial(CSX, 'RO4350B', substrate_epr, 0.02, 1e9, 100e9, 'f1', 10^4/(2*pi));
function [CSX] = AddDjordjevicSarkarMaterial(varargin)

   p = inputParser();


   p.addRequired('CSX',      @isstruct);
   p.addRequired('matName',  @ischar);
   p.addRequired('epsRMeas', @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addRequired('tandMeas', @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addRequired('fMeas',    @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addRequired('f2',       @(x) (x >= 0) && isnumeric(x) && isscalar(x));

   p.addParameter('lowFreqEvalType',0, @(x) (x >= 0) && (round(x) == x)  && isscalar(x));
   p.addParameter('f1', 0,             @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addParameter('epsDC', 0,          @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addParameter('sigma', 0,          @(x) (x >= 0) && isnumeric(x) && isscalar(x));
   p.addParameter('nTermsPerDec', 1,   @(x) (x >= 1) && isnumeric(x) && isscalar(x));

   p.FunctionName = 'AddDjordjevicSarkarMaterial';
   p.parse(varargin{:})

   if ((p.Results.lowFreqEvalType == 0) && any(strcmp(p.UsingDefaults, 'f1')))
     error('For ''lowFreqEvalType=0'' a value for f1 must be specified.');
   end

   if ((p.Results.lowFreqEvalType == 1) && any(strcmp(p.UsingDefaults, 'epsDC')))
     error('For ''lowFreqEvalType=1'' a value for epsDC must be specified.');
   end

   % Fit the model and receive Lorentz model parametes for openEMS
   paramLorentz = calcDjordjevicSarkarApprox(...
      p.Results.epsRMeas,...
      p.Results.tandMeas,...
      p.Results.fMeas,...
      p.Results.f2,...
      'lowFreqEvalType', p.Results.lowFreqEvalType,...
      'f1', p.Results.f1,...
      'epsDC', p.Results. epsDC,...
      'sigma', p.Results.sigma,...
      'nTermsPerDec', p.Results.nTermsPerDec);

      CSX = p.Results.CSX;
      matName = p.Results.matName;

      CSX = AddLorentzMaterial(CSX, matName);
      CSX = SetMaterialProperty(CSX, matName,'Epsilon', paramLorentz.epsInf, 'Kappa', paramLorentz.sigma); % Epsilon here is acutally epsilonInf

      CSX = SetMaterialProperty(CSX, matName,...
       'EpsilonPlasmaFrequency',  paramLorentz.fp(1),...
       'EpsilonLorPoleFrequency', paramLorentz.fl(1),...
       'EpsilonRelaxTime',        paramLorentz.taup(1));

      for i = 2:length(paramLorentz.fp)

        CSX = SetMaterialProperty(CSX, matName,...
          ['EpsilonPlasmaFrequency_',  int2str(i)], paramLorentz.fp(i),...
          ['EpsilonLorPoleFrequency_', int2str(i)], paramLorentz.fl,...
          ['EpsilonRelaxTime_',        int2str(i)], paramLorentz.taup(i));

      end
end
