function report = run_demo(showFigures)
%RUN_DEMO Run the averaged Simulink test and a separate exact PWM check.
if nargin==0, showFigures=true; end
root=fileparts(mfilename('fullpath')); previous=pwd;
cleanup=onCleanup(@() cd(previous)); cd(root);
clear sl_plant sl_controller
p=project_parameters(); [p,timing]=plan_experiment(p);
[t,reference,~]=simulate_case(p,p.stopTime);
times=[0;p.softStart;p.loadTime;p.loadTime;p.lineTime;p.lineTime;p.stopTime];
values=zeros(numel(times),3);
for k=1:numel(times)
    time=times(k);
    if k==3 || k==5, time=time-p.sampleTime/10; end
    values(k,:)=experiment_input(time,p).';
end
inputSignal=[times,values];
in=Simulink.SimulationInput(p.modelName);
in=in.setVariable('p',p,'Workspace',p.modelName);
in=in.setVariable('inputSignal',inputSignal,'Workspace',p.modelName);
in=in.setModelParameter('StopTime',num2str(p.stopTime,12), ...
    'Solver','ode45','MaxStep',num2str(p.sampleTime,12), ...
    'RelTol','1e-8','AbsTol','1e-10','OutputOption','SpecifiedOutputTimes', ...
    'OutputTimes',mat2str(t.'));
out=sim(in);
states=interp1(out.states.Time,out.states.Data,t,'pchip');
control=interp1(out.control.Time,out.control.Data,t,'pchip');
error=max(abs(states-reference(:,1:p.stateCount)),[],'all');
assert(error<2e-3,'Simulink disagrees with the interval-by-interval ODE solution.');
assert(all(control(:,1)>=-1e-9 & control(:,1)<=p.maximumDuty+1e-9),'Duty bounds failed.');
assert(max(control(:,4))<=p.currentLimit+1e-8,'Current request bound failed.');
inputs=zeros(numel(t),3);
for k=1:numel(t), inputs(k,:)=experiment_input(t(k),p).'; end
[switching,ripple]=switching_check(p);
report.verification='PASS'; report.ode_max_state_error=error;
report.switching=ripple; report.stop_time_s=p.stopTime;
report.final_voltage_error_V=abs(states(end,end)-p.reference);
report.peak_inductor_current_A=max(states(:,1));
if ~isfolder('results'), mkdir('results'); end
names={'time_s','input_V','load_ohm','reference_V','inductor_A','output_V','duty','current_request_A'};
if p.stateCount==4
    names={'time_s','input_V','load_ohm','reference_V','input_inductor_A', ...
        'output_inductor_A','coupling_capacitor_V','output_V','duty','current_request_A'};
end
writetable(array2table([t,inputs,states,control(:,[1,4])], ...
    'VariableNames',names),'results/response.csv');
names=[{'time_s'},compose('state_%d',1:p.stateCount),{'gate'}];
writetable(array2table(switching,'VariableNames',names),'results/switching.csv');
write_json('results/parameters.json',p);write_json('results/timing.json',timing);
write_json('results/metrics.json',report);
plot_results(t,states,control,inputs,switching,p,showFigures);
fprintf('%s verification PASS; state error %.3g; endpoint %.6g s.\n',upper(p.topology),error,p.stopTime);
end

function write_json(path,value)
file=fopen(path,'w'); assert(file~=-1,'Cannot write result.');
cleanup=onCleanup(@() fclose(file));
fprintf(file,'%s\n',jsonencode(value,'PrettyPrint',true));
end
