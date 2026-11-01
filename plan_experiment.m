function [p,timing] = plan_experiment(p)
%PLAN_EXPERIMENT Wait for both loops and the power stage before each event.
p.loadTime = Inf; p.lineTime = Inf;
[t,x,u] = simulate_case(p,p.sizingHorizon);
first = settled_at(t,x,u,p.softStart,p);
p.loadTime = first+p.sampleTime;
[t,x,u] = simulate_case(p,p.sizingHorizon);
second = settled_at(t,x,u,p.loadTime,p);
p.lineTime = second+p.sampleTime;
[t,x,u] = simulate_case(p,p.sizingHorizon);
last = settled_at(t,x,u,p.lineTime,p);
p.stopTime = ceil((last+0.1*(last-p.lineTime))/p.sampleTime)*p.sampleTime;
timing = struct('startup_settled_at_s',first,'load_change_at_s',p.loadTime, ...
    'load_settled_at_s',second,'line_change_at_s',p.lineTime, ...
    'final_settled_at_s',last,'stop_time_s',p.stopTime,'tail_fraction',0.1);
timing.criteria = '2% reference for output voltage; 2% final-phase excursion for other states and duty';
end

function time = settled_at(t,x,u,startTime,p)
selected = find(t>=startTime);
signals = [x(:,1:p.stateCount),u(:,1)];
input = experiment_input(startTime+p.sampleTime,p);
[steady,duty] = operating_point(input(1),input(2),p.reference,p);
target = [steady.',duty];
deviation = signals(selected,:)-target;
tolerance = max(0.02*max(abs(deviation),[],1),1e-7);
tolerance(p.stateCount) = 0.02*p.reference;
outside = any(abs(deviation)>tolerance,2);
last = find(outside,1,'last');
if isempty(last), time=startTime; return; end
assert(last<numel(selected)-10,'Increase sizing horizon: a response has not settled.');
time = t(selected(last+1));
end
