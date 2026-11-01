function [trace,metrics] = switching_check(p)
%SWITCHING_CHECK Exact piecewise-linear PWM solution at the final DC point.
[steady,duty] = operating_point(p.lineVoltage,p.loadedResistance,p.reference,p);
n = p.stateCount; period = 1/p.switchingFrequency;
on = state_matrix(1,p); off = state_matrix(0,p);
cycle = expm(off*(1-duty)*period)*expm(on*duty*period);
state = [(eye(n)-cycle(1:n,1:n))\cycle(1:n,end);1];
initial = state;
trace = zeros(5*202,n+2); row=0;
for k=0:4
    for gate=1:-1:0
        fraction = duty;
        matrix = on;
        if gate==0, fraction=1-duty; matrix=off; end
        step = fraction*period/100;
        transition = expm(matrix*step);
        offset = k*period+(1-gate)*duty*period;
        for j=0:100
            row=row+1;
            trace(row,:) = [offset+j*step,state(1:n).',gate];
            if j<100, state=transition*state; end
        end
    end
end
t = trace(:,1); x=trace(:,2:n+1); gate=trace(:,end);
average = trapz(t,x)/(t(end)-t(1));
inputCurrent = x(:,1);
if strcmp(p.topology,'buck'), inputCurrent=gate.*inputCurrent; end
outputPower = x(:,end).^2/p.loadedResistance;
loss = p.windingResistance*x(:,1).^2;
if n==4, loss=loss+p.windingResistance*x(:,2).^2; end
balance = trapz(t,p.lineVoltage*inputCurrent-outputPower-loss)/(t(end)-t(1));
metrics.mean_voltage_V = average(end);
metrics.mean_voltage_error_percent = 100*abs(average(end)-steady(end))/p.reference;
metrics.voltage_ripple_peak_to_peak_V = max(x(:,end))-min(x(:,end));
metrics.inductor_ripple_peak_to_peak_A = max(x(:,1))-min(x(:,1));
metrics.minimum_rectifier_current_A = min(x(:,1));
if n==4, metrics.minimum_rectifier_current_A=min(x(:,1)+x(:,2)); end
metrics.cycle_state_residual = norm(state-initial,Inf);
metrics.power_balance_residual_W = balance;
metrics.duty = duty;
assert(metrics.mean_voltage_error_percent<1,'PWM mean disagrees with averaged DC balance.');
assert(metrics.minimum_rectifier_current_A>0,'PWM check left continuous conduction.');
assert(metrics.cycle_state_residual<1e-8,'PWM trace is not periodic.');
assert(abs(balance)<0.01*mean(outputPower),'Switching power balance failed.');
end

function matrix = state_matrix(gate,p)
n=p.stateCount; zero=zeros(n,1);
b=power_stage(zero,gate,p.lineVoltage,p.loadedResistance,p);
matrix=zeros(n+1);
for k=1:n
    unit=zero; unit(k)=1;
    matrix(1:n,k)=power_stage(unit,gate,p.lineVoltage,p.loadedResistance,p)-b;
end
matrix(1:n,end)=b;
end
