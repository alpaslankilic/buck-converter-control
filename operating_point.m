function [x,duty] = operating_point(vin,resistance,voltage,p)
%OPERATING_POINT Solve the lossy DC balance without treating a probe endpoint as steady.
duty = fzero(@(d) voltage_error(d,vin,resistance,voltage,p),[1e-5,p.maximumDuty]);
x = equilibrium(duty,vin,resistance,p);
assert(norm(power_stage(x,duty,vin,resistance,p),Inf)<1e-7,'DC balance failed.');
end

function error = voltage_error(d,vin,resistance,voltage,p)
x = equilibrium(d,vin,resistance,p);
error = x(end)-voltage;
end

function x = equilibrium(d,vin,resistance,p)
zero = zeros(p.stateCount,1);
b = power_stage(zero,d,vin,resistance,p);
A = zeros(p.stateCount);
for k=1:p.stateCount
    unit = zero; unit(k)=1;
    A(:,k) = power_stage(unit,d,vin,resistance,p)-b;
end
x = -A\b;
end
