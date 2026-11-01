function plot_results(t,x,u,input,pwm,p,visible)
%PLOT_RESULTS Separate regulation, control effort, and switching ripple.
blue=[0 .36 .60]; orange=[.8 .32 .05];
[fig,layout]=new_figure('Voltage regulation',2,visible);
ax=nexttile(layout);hold(ax,'on');
plot(ax,1e3*t,input(:,3),':','Color',[.4 .4 .4],'LineWidth',1.4,'DisplayName','Voltage request');
plot(ax,1e3*t,x(:,end),'Color',blue,'LineWidth',1.7,'DisplayName','Averaged output');
events(ax,p);ylabel(ax,'Output voltage [V]');
title(ax,'(a) Soft-start, load rejection and line regulation','FontWeight','normal');
legend(ax,'Location','southoutside','Orientation','horizontal','Box','off');style(ax,t);
ax=nexttile(layout);hold(ax,'on');
plot(ax,1e3*t,input(:,1),'Color',orange,'LineWidth',1.7,'DisplayName','Supply voltage');
events(ax,p);ylabel(ax,'Supply voltage [V]');xlabel(ax,'Time [ms]');
title(ax,'(b) Independent supply-voltage change','FontWeight','normal');style(ax,t);
save_figure(fig,'01_voltage_regulation',visible);

[fig,layout]=new_figure('Current and duty',2,visible);
ax=nexttile(layout);hold(ax,'on');
plot(ax,1e3*t,u(:,4),'--','Color',[.45 .45 .45],'LineWidth',1.2,'DisplayName','Current request');
plot(ax,1e3*t,x(:,1),'Color',blue,'LineWidth',1.7,'DisplayName','Input inductor');
if p.stateCount==4
    plot(ax,1e3*t,x(:,2),'Color',orange,'LineWidth',1.3,'DisplayName','Output inductor');
end
events(ax,p);ylabel(ax,'Inductor current [A]');
title(ax,'(a) Cascaded current loop','FontWeight','normal');
legend(ax,'Location','southoutside','Orientation','horizontal','Box','off');style(ax,t);
ax=nexttile(layout);plot(ax,1e3*t,u(:,1),'Color',blue,'LineWidth',1.7);
events(ax,p);ylabel(ax,'Duty ratio');xlabel(ax,'Time [ms]');
title(ax,'(b) Bounded duty command','FontWeight','normal');style(ax,t);
save_figure(fig,'02_current_and_duty',visible);

[fig,layout]=new_figure('Steady-state PWM verification',2,visible);
time=1e6*pwm(:,1); n=p.stateCount;
ax=nexttile(layout);plot(ax,time,pwm(:,n+1),'Color',blue,'LineWidth',1.6);
ylabel(ax,'Output voltage [V]');grid(ax,'on');
title(ax,'(a) Periodic switching ripple at the final operating point','FontWeight','normal');style(ax,[]);
ax=nexttile(layout);plot(ax,time,pwm(:,2),'Color',orange,'LineWidth',1.6);
ylabel(ax,'Input-inductor current [A]');xlabel(ax,'Time [microseconds]');
title(ax,'(b) Exact on/off state transitions at 50 kHz','FontWeight','normal');style(ax,[]);
save_figure(fig,'03_switching_ripple',visible);
end

function events(ax,p)
xline(ax,1e3*p.loadTime,'--','Load change','Color',[.45 .2 .55], ...
    'LabelOrientation','horizontal','FontSize',10,'HandleVisibility','off');
xline(ax,1e3*p.lineTime,':','Supply change','Color',[.45 .2 .55], ...
    'LabelOrientation','horizontal','FontSize',10,'HandleVisibility','off');
limits=ylim(ax);ylim(ax,[limits(1),limits(2)+.18*diff(limits)]);
end

function [fig,layout]=new_figure(name,panels,visible)
state='off';if visible,state='on';end
fig=figure('Name',name,'Visible',state,'Color','w','Position',[100 80 980 590]);
layout=tiledlayout(fig,panels,1,'TileSpacing','compact','Padding','loose');
end

function style(ax,t)
set(ax,'FontName','Arial','FontSize',12,'Box','off','TickDir','out', ...
    'YGrid','on','GridAlpha',.12,'LineWidth',.8);
if ~isempty(t),xlim(ax,[0,1e3*t(end)]);end
end

function save_figure(fig,name,visible)
exportgraphics(fig,fullfile('results',[name '.png']),'Resolution',200,'Padding',8,'Units','points');
exportgraphics(fig,fullfile('results',[name '.pdf']),'ContentType','vector','Padding',8,'Units','points');
if ~visible,close(fig);end
end
