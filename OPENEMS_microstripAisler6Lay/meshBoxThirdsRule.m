
function [meshX, meshY] = meshBoxThirdsRule(start, stop, meshResEdge, startEn, stopEn)

  if (nargin < 5), startEn = [1, 1]; end;
  if (nargin < 4), startEn = [1, 1]; stopEn = [1, 1]; end;

  meshX = [];
  meshY = [];
  
  dVec = stop(1:2) - start(1:2); % delta Vector
  
  if all(abs(dVec) < 1e-9)
    error('At least one box dimension in x or y is smaller than 1e-9 units.');
  end

  % Start coordinate: dVev positive -> Inner meshline shifed in positive x 
  meshLinesStart(1:2) = start(1:2) + sign(dVec)*1/3*meshResEdge;
  meshLinesStart(3:4) = start(1:2) - sign(dVec)*2/3*meshResEdge;
  
  % Stop coordinate: dVev positive -> Inner meshline shifed in negative x 
  meshLinesStop(1:2) = stop(1:2) - sign(dVec)*1/3*meshResEdge;
  meshLinesStop(3:4) = stop(1:2) + sign(dVec)*2/3*meshResEdge;
  
  meshX = [];
  meshY = [];
    
  if startEn(1) %X
    meshX = [meshX, meshLinesStart(1)];
    meshX = [meshX, meshLinesStart(3)];
  end
  
  if startEn(2) %Y
    meshY = [meshY, meshLinesStart(2)];
    meshY = [meshY, meshLinesStart(4)];
  end
    
  if stopEn(1) %X
    meshX = [meshX, meshLinesStop(1)];
    meshX = [meshX, meshLinesStop(3)];
  end
  
  if stopEn(2) %Y
    meshY = [meshY, meshLinesStop(2)];
    meshY = [meshY, meshLinesStop(4)];
  end
end

##    meshX = meshLines(1:2:7);
##    meshY = meshLines(2:2:8);