function [t,x,command] = simulate_case(p,stopTime)
%SIMULATE_CASE Integrate each input interval separately to preserve step times.
t = (0:p.sampleTime:stopTime).';
knots = unique([0,p.softStart,p.loadTime,p.lineTime,stopTime]);
knots = knots(isfinite(knots) & knots>=0 & knots<=stopTime);
state = [p.initialState;p.initialIntegral;p.initialDutyCorrection];
x = zeros(numel(t),numel(state));
options = odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',p.sampleTime);
for k = 1:numel(knots)-1
    left = knots(k); right = knots(k+1);
    solution = ode45(@(time,y) closed_loop(time,y,p,left,right),[left,right],state,options);
    selected = t>=left & t<=right;
    x(selected,:) = deval(solution,t(selected)).';
    state = solution.y(:,end);
end
command = zeros(numel(t),2);
for k = 1:numel(t)
    input = experiment_input(t(k),p);
    [command(k,1),~,command(k,2)] = voltage_controller( ...
        x(k,1:p.stateCount).',x(k,p.stateCount+1:end).',input(1),input(3),p);
end
end

function dy = closed_loop(t,y,p,left,right)
% Keep discontinuous inputs constant on the interior side of each segment.
time = min(max(t,left),right-eps(max(1,right)));
input = experiment_input(time,p);
x = y(1:p.stateCount); z = y(p.stateCount+1:end);
[d,dz] = voltage_controller(x,z,input(1),input(3),p);
dy = [power_stage(x,d,input(1),input(2),p);dz];
end
