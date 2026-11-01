function [d,dz,currentRequest] = voltage_controller(x,z,vin,reference,p)
%VOLTAGE_CONTROLLER Cascaded voltage/current PI loops with back-calculation.
voltageError = reference-x(end);
request = p.Kpv*voltageError+z(1);
currentRequest = min(p.currentLimit,max(0,request));
switch p.topology
    case 'buck'
        feedforward = x(2)/vin;
    case 'boost'
        feedforward = 1-vin/max(vin,x(2));
    case 'sepic'
        feedforward = 1-vin/max(vin,x(3)+x(4));
end
currentError = currentRequest-x(1);
command = feedforward+p.Kpi*currentError+z(2);
d = min(p.maximumDuty,max(0,command));
dz = [p.Kiv*voltageError+p.voltageTracking*(currentRequest-request); ...
    p.Kii*currentError+p.currentTracking*(d-command)];
end
