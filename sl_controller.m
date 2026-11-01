function output = sl_controller(u)
%SL_CONTROLLER Controller interface: plant states, PI states, supply, request.
persistent p
if isempty(p), p=project_parameters(); end
n = p.stateCount;
[d,dz,request] = voltage_controller(u(1:n),u(n+1:n+2),u(n+3),u(n+4),p);
output = [d;dz;request];
end
