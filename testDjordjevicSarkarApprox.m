clear;
close all;
clc;

sigmaDC = 0;

[paramDebye, paramSarkar] = calcDjordjevicSarkarApprox('fMeas', 10e9, 'epsRMeas', 4, 'tandMeas', 0.02,...
                                                       'f1', 10^-log10(2*pi)*1e4, 'f2', 10^-log10(2*pi)*1e5, ...
                                                       'lowFreqEvalType', 0,  'epsRdc', 4.475156, 'sigmaDC', sigmaDC, 'nTermsPerDec', 1, 'plotEn', 1)


eps0 = 8.8541878128e-12; %F/m
epsInfSarkar = paramSarkar.epsInf;
deltaEpsTsarkar = paramSarkar.deltaEpsT;
m2 = paramSarkar.m2;
m1 = paramSarkar.m1;
w1 = 10^m1;
w2 = 10^m2;
sigmaDC = sigmaDC;

epsRSarkarEq = @(x) epsInfSarkar + deltaEpsTsarkar/(m2-m1)*log10((w2+1i*x)./(w1+1i*x)) - 1i*sigmaDC./(x*eps0);

epsRSarkarEq(2*pi*1e9)
