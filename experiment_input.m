function input = experiment_input(t,p)
%EXPERIMENT_INPUT Soft-start, then separate load and line changes.
reference = p.startVoltage+(p.reference-p.startVoltage)*min(1,t/p.softStart);
vin = p.inputVoltage+(p.lineVoltage-p.inputVoltage)*(t>=p.lineTime);
resistance = p.resistance+(p.loadedResistance-p.resistance)*(t>=p.loadTime);
input = [vin;resistance;reference];
end
