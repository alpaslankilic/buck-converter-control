function p = project_parameters()
%PROJECT_PARAMETERS SI units; current and voltage loop bandwidths are separated.
p.topology = 'buck';
p.modelName = 'buck_converter';
p.inputVoltage = 24; p.lineVoltage = 20;
p.reference = 12; p.startVoltage = 0;
p.resistance = 6; p.loadedResistance = 4;
p.L = 0.0002; p.C = 0.00022;
p.couplingCapacitance = 100e-6;
p.windingResistance = 0.04;
p.switchingFrequency = 50e3;
p.currentLimit = 5; p.maximumDuty = 0.90;
p.stateCount = 2;
p.initialState = [0;0];
p.initialIntegral = p.initialState(1);
p.initialDutyCorrection = 0;
p.softStart = 0.005;
p.sampleTime = 2e-05;
p.sizingHorizon = 0.1;
p.loadTime = Inf; p.lineTime = Inf; p.stopTime = p.sizingHorizon;
voltageRate = 2*pi*800; currentRate = 2*pi*6000;
delivery = p.inputVoltage/p.reference;
if strcmp(p.topology,'buck'), delivery=1; end
p.Kpv = p.C*voltageRate/delivery;
p.Kiv = p.Kpv*voltageRate/5;
switchVoltage = p.reference;
if strcmp(p.topology,'buck'), switchVoltage=p.inputVoltage; end
if strcmp(p.topology,'sepic'), switchVoltage=p.inputVoltage+p.reference; end
p.Kpi = p.L*currentRate/switchVoltage;
p.Kii = p.Kpi*currentRate/10;
p.voltageTracking = voltageRate;
p.currentTracking = currentRate;
if p.startVoltage>0
    [p.initialState,duty] = operating_point(p.inputVoltage,p.resistance,p.startVoltage,p);
    p.initialIntegral = p.initialState(1);
    [feedforward,~] = voltage_controller(p.initialState,[p.initialIntegral;0], ...
        p.inputVoltage,p.startVoltage,p);
    p.initialDutyCorrection = duty-feedforward;
end
end
