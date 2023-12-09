function [CSX, meshX, meshY] = constructVia(CSX, pos, posZstackup, viaType, meshXin, meshYin);

  if (nargin < 5), meshXin = []; end
  if (nargin < 6), meshYin = []; end

  numLayers = ceil(length(posZstackup)/2);

  % Define Drill
  start = [pos(1), pos(2), posZstackup(1)];
  stop =  [pos(1), pos(2), posZstackup(end)];
  CSX = AddCylinder(CSX, viaType.drill.matName, viaType.drill.prio, start, stop, viaType.drill.diam/2);

  for i=1:numLayers
    start(3) = posZstackup(i*2-1);
    stop(3) =  posZstackup(i*2);

    % Define coverpad
    if viaType.cp(i).en
      CSX = AddCylinder(CSX, viaType.cp(i).matName, viaType.cp(i).prio, start, stop, viaType.cp(i).diam/2);
    end

    % Define plane clearance
    if viaType.clear(i).en
      CSX = AddCylinder(CSX, viaType.clear(i).matName, viaType.clear(i).prio, start, stop, viaType.clear(i).diam/2);
    end
  end

  % Meshlines for the drill
  meshX = [pos(1) + viaType.drill.diam/2,...
           pos(1) - viaType.drill.diam/2];

  meshY = [pos(2) + viaType.drill.diam/2,...
           pos(2) - viaType.drill.diam/2];

  for i=1:numLayers
    % Meshlines for the coverpad
    if viaType.cp(i).en
      meshX = [meshX, pos(1) + viaType.cp(i).diam/2];
      meshX = [meshX, pos(1) - viaType.cp(i).diam/2];

      meshY = [meshY, pos(2) + viaType.cp(i).diam/2];
      meshY = [meshY, pos(2) - viaType.cp(i).diam/2];
    end

    % Meshlines for the via clearance guard ring
    if viaType.clear(i).en
      meshX = [meshX, pos(1) + viaType.clear(i).diam/2];
      meshX = [meshX, pos(1) - viaType.clear(i).diam/2];

      meshY = [meshY, pos(2) + viaType.clear(i).diam/2];
      meshY = [meshY, pos(2) - viaType.clear(i).diam/2];
    end
  end

  % Append positions
  meshX = [meshXin, meshX];
  meshY = [meshYin, meshY];

  meshX = unique(meshX);
  meshY = unique(meshY);

  % The z-mesh is assumed to be implemented by the stackup already
end
