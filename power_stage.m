function dx = power_stage(x,d,vin,resistance,p)
%POWER_STAGE Continuous-conduction state equations, including winding losses.
d = min(1,max(0,d));
switch p.topology
    case 'buck'
        dx = [(d*vin-x(2)-p.windingResistance*x(1))/p.L; ...
            (x(1)-x(2)/resistance)/p.C];
    case 'boost'
        dx = [(vin-(1-d)*x(2)-p.windingResistance*x(1))/p.L; ...
            ((1-d)*x(1)-x(2)/resistance)/p.C];
    case 'sepic'
        dx = [(vin-(1-d)*(x(3)+x(4))-p.windingResistance*x(1))/p.L; ...
            (d*x(3)-(1-d)*x(4)-p.windingResistance*x(2))/p.L; ...
            ((1-d)*x(1)-d*x(2))/p.couplingCapacitance; ...
            ((1-d)*(x(1)+x(2))-x(4)/resistance)/p.C];
end
end
