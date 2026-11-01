function dx = sl_plant(u)
%SL_PLANT Plant interface: states, duty, input voltage, load resistance.
persistent p
if isempty(p), p=project_parameters(); end
n = p.stateCount;
dx = power_stage(u(1:n),u(n+1),u(n+2),u(n+3),p);
end
